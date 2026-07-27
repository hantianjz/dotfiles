vim.opt.runtimepath:prepend(vim.fn.getcwd() .. "/nvim")

local module = require("clangd_compiler_includes")
local uv = vim.uv

local tests = {}

local function test(name, callback)
  table.insert(tests, { name = name, callback = callback })
end

local function equal(expected, actual, message)
  if not vim.deep_equal(expected, actual) then
    error(("%s\nexpected: %s\nactual:   %s"):format(
      message or "values differ",
      vim.inspect(expected),
      vim.inspect(actual)
    ), 2)
  end
end

local function truthy(value, message)
  if not value then
    error(message or "expected a truthy value", 2)
  end
end

local function write(path, contents, mode)
  local file = assert(io.open(path, "w"))
  file:write(contents)
  file:close()
  if mode then
    assert(uv.fs_chmod(path, mode))
  end
end

local function mkdir(path)
  vim.fn.mkdir(path, "p")
end

local function json_write(path, value)
  write(path, vim.json.encode(value))
end

local function fixture()
  local base = vim.fn.tempname()
  local project = base .. "/project"
  local bin = base .. "/bin"
  local includes = base .. "/includes"
  mkdir(project)
  mkdir(bin)
  mkdir(includes .. "/common")
  mkdir(includes .. "/c")
  mkdir(includes .. "/cpp")
  includes = assert(uv.fs_realpath(includes))

  local helper = base .. "/helper"
  write(helper, [[#!/bin/sh
if [ -n "$CLANGD_TEST_LOG" ]; then
  printf '%s\n' "$*" >> "$CLANGD_TEST_LOG"
fi
if [ "$1" = "$CLANGD_FAIL_COMPILER" ]; then
  echo "deliberate failure" >&2
  exit 7
fi
if [ "$1" = "$CLANGD_SLOW_COMPILER" ]; then
  sleep 1
fi
printf '%s\n' "$CLANGD_INCLUDE_BASE/common"
printf '%s\n' "$CLANGD_INCLUDE_BASE/common"
case "$*" in
  *"-x c++"*) printf '%s\n' "$CLANGD_INCLUDE_BASE/cpp" ;;
  *) printf '%s\n' "$CLANGD_INCLUDE_BASE/c" ;;
esac
printf '%s\n' "$CLANGD_INCLUDE_BASE/missing"
]], 493)

  local function compiler(name, directory)
    directory = directory or bin
    mkdir(directory)
    local path = directory .. "/" .. name
    write(path, "#!/bin/sh\nexit 0\n", 493)
    return path
  end

  compiler("hermit")
  assert(uv.fs_symlink("hermit", bin .. "/.arm-none-eabi-gcc.pkg"))
  assert(uv.fs_symlink(".arm-none-eabi-gcc.pkg", bin .. "/arm-none-eabi-gcc"))
  compiler("arm-none-eabi-g++")
  compiler("host-gcc")
  compiler("override-gcc")
  compiler("failing-gcc")
  compiler("slow-gcc")

  local old_path = vim.env.PATH
  local environment_keys = {
    "CLANGD_TEST_LOG",
    "CLANGD_FAIL_COMPILER",
    "CLANGD_SLOW_COMPILER",
    "CLANGD_INCLUDE_BASE",
  }
  local old_values = {}
  for _, key in ipairs(environment_keys) do
    old_values[key] = vim.env[key] or false
  end
  vim.env.PATH = bin .. ":" .. old_path
  vim.env.CLANGD_TEST_LOG = base .. "/probe.log"
  vim.env.CLANGD_INCLUDE_BASE = includes
  vim.env.CLANGD_FAIL_COMPILER = vim.fs.normalize(bin .. "/failing-gcc")
  vim.env.CLANGD_SLOW_COMPILER = vim.fs.normalize(bin .. "/slow-gcc")

  return {
    base = base,
    bin = bin,
    compiler = compiler,
    helper = helper,
    includes = includes,
    project = project,
    cleanup = function()
      vim.env.PATH = old_path
      for _, key in ipairs(environment_keys) do
        vim.env[key] = old_values[key] or nil
      end
      vim.fn.delete(base, "rf")
    end,
  }
end

local function invoke(f, options, initial)
  options = options or {}
  local notifications = {}
  local original_notify = vim.notify
  vim.notify = function(message, level)
    if message:find("clangd compiler include discovery:", 1, true) == 1 then
      table.insert(notifications, { message = message, level = level })
    end
  end

  local params = {
    rootUri = vim.uri_from_fname(f.project),
    initializationOptions = initial,
  }
  local config = { root_dir = f.project }
  local callback = module.make_before_init({
    helper_path = options.helper_path or f.helper,
    target = "arm-none-eabi",
    timeout = options.timeout or 5000,
    fallback_compiler = "arm-none-eabi-gcc",
  })
  local ok, failure = pcall(callback, params, config)
  vim.wait(20, function()
    return #notifications > 0
  end)
  vim.notify = original_notify
  if not ok then
    error(failure)
  end
  return params, config, notifications
end

local function arm_config(extra)
  local result = ([[
CompileFlags:
  CompilationDatabase: build
  Add:
    - --target=arm-none-eabi
    - -mcpu=cortex-m33
    - --sysroot
    - /sdk
% s
]]):gsub("%% s", extra or "")
  return result
end

local function command_for(file, compiler, arguments)
  local result = { compiler }
  vim.list_extend(result, arguments or {})
  table.insert(result, "-c")
  table.insert(result, file)
  return result
end

test("stays inactive for non-ARM and commented targets", function()
  local f = fixture()
  write(f.project .. "/.clangd", [[
CompileFlags:
  Add:
    # - --target=arm-none-eabi
    - --target=x86_64-unknown-linux-gnu
]])
  local initial = { fallbackFlags = { "-Wall" } }
  local params, config, notifications = invoke(f, nil, initial)
  equal(initial, params.initializationOptions)
  equal(nil, config._clangd_compiler_includes_status)
  equal(0, #notifications, vim.inspect(notifications))
  f.cleanup()
end)

test("handles arguments, quoted commands, languages, flags, duplicates, and separators", function()
  local f = fixture()
  mkdir(f.project .. "/build")
  write(f.project .. "/.clangd", arm_config())
  json_write(f.project .. "/build/compile_commands.json", {
    {
      directory = f.project,
      file = "one.c",
      arguments = command_for(
        "one.c",
        "arm-none-eabi-gcc",
        { "-mcpu=cortex-m33", "-mthumb", "--", "tail" }
      ),
    },
    {
      directory = f.project,
      file = "one.c",
      arguments = command_for("one.c", "cc", { "-mthumb" }),
    },
    {
      directory = f.project,
      file = "two file.cpp",
      command = "arm-none-eabi-g++ -DNAME='two words' -c 'two file.cpp'",
    },
  })

  local existing_file = f.project .. "/one.c"
  local params, config, notifications = invoke(f, nil, {
    fallbackFlags = { "-Wall", "--", "fallback-tail" },
    compilationDatabaseChanges = {
      [existing_file] = {
        workingDirectory = "/preserved",
        compilationCommand = { "clang", "-DEXISTING", "--", "tail" },
      },
      ["/unrelated.c"] = {
        workingDirectory = "/unrelated",
        compilationCommand = { "clang", "/unrelated.c" },
      },
    },
  })

  local changes = params.initializationOptions.compilationDatabaseChanges
  equal("/preserved", changes[existing_file].workingDirectory)
  equal({
    "clang", "-DEXISTING",
    "-isystem", f.includes .. "/common",
    "-isystem", f.includes .. "/c",
    "--", "tail",
  }, changes[existing_file].compilationCommand)
  truthy(changes[f.project .. "/two file.cpp"])
  equal({ "clang", "/unrelated.c" }, changes["/unrelated.c"].compilationCommand)
  equal({
    "-Wall",
    "-isystem", f.includes .. "/common",
    "-isystem", f.includes .. "/c",
    "-isystem", f.includes .. "/cpp",
    "--", "fallback-tail",
  }, params.initializationOptions.fallbackFlags)
  equal(3, config._clangd_compiler_includes_status.include_count)
  equal(2, config._clangd_compiler_includes_status.command_count)
  equal(0, #notifications, vim.inspect(notifications))

  local log = assert(io.open(f.base .. "/probe.log")):read("*a")
  truthy(log:find("-mcpu=cortex%-m33"))
  for line in log:gmatch("[^\n]+") do
    local _, cpu_count = line:gsub("-mcpu=cortex%-m33", "")
    truthy(cpu_count <= 1)
  end
  truthy(log:find("%-%-sysroot /sdk"))
  truthy(log:find("-mthumb", 1, true))
  truthy(log:find("-x c++", 1, true))
  truthy(log:find("/arm%-none%-eabi%-gcc"))
  truthy(not log:find("/hermit", 1, true))
  truthy(not log:find("/cc ", 1, true))
  f.cleanup()
end)

test("uses Compiler override and probes once per signature", function()
  local f = fixture()
  mkdir(f.project .. "/build")
  write(f.project .. "/.clangd", arm_config("  Compiler: override-gcc"))
  json_write(f.project .. "/build/compile_commands.json", {
    {
      directory = f.project,
      file = "one.c",
      arguments = command_for("one.c", "/not/trusted/compiler"),
    },
    {
      directory = f.project,
      file = "two.c",
      arguments = command_for("two.c", "arm-none-eabi-gcc"),
    },
  })
  local _, config, notifications = invoke(f)
  equal("override-gcc", config._clangd_compiler_includes_status.compiler)
  equal(2, config._clangd_compiler_includes_status.command_count)
  equal(0, #notifications, vim.inspect(notifications))
  local log = assert(io.open(f.base .. "/probe.log")):read("*a")
  local count = select(2, log:gsub("\n", "\n"))
  equal(1, count)
  f.cleanup()
end)

test("supports multiple compilers", function()
  local f = fixture()
  mkdir(f.project .. "/build")
  write(f.project .. "/.clangd", arm_config())
  json_write(f.project .. "/build/compile_commands.json", {
    {
      directory = f.project,
      file = "one.c",
      arguments = command_for("one.c", "arm-none-eabi-gcc"),
    },
    {
      directory = f.project,
      file = "two.cpp",
      arguments = command_for("two.cpp", "arm-none-eabi-g++"),
    },
  })
  local _, config = invoke(f)
  equal("arm-none-eabi-g++, arm-none-eabi-gcc", config._clangd_compiler_includes_status.compiler)
  equal(2, config._clangd_compiler_includes_status.command_count)
  f.cleanup()
end)

test("does not inject ARM includes into conditional host database files", function()
  local f = fixture()
  mkdir(f.project .. "/build/firmware")
  mkdir(f.project .. "/build/host")
  mkdir(f.project .. "/test/firmware")
  write(f.project .. "/.clangd", [[
CompileFlags:
  CompilationDatabase: build/firmware
  Add:
    - --target=arm-none-eabi
    - -mcpu=cortex-m33
---
If:
  PathMatch:
    - test/.*
  PathExclude: test/firmware/.*
CompileFlags:
  CompilationDatabase: build/host
]])
  json_write(f.project .. "/build/firmware/compile_commands.json", {
    {
      directory = f.project,
      file = "main.c",
      arguments = command_for("main.c", "arm-none-eabi-gcc"),
    },
    {
      directory = f.project,
      file = "test/unit.c",
      arguments = command_for("test/unit.c", "arm-none-eabi-gcc"),
    },
    {
      directory = f.project,
      file = "test/firmware/special.c",
      arguments = command_for("test/firmware/special.c", "arm-none-eabi-gcc"),
    },
  })
  json_write(f.project .. "/build/host/compile_commands.json", {
    {
      directory = f.project,
      file = "main.c",
      arguments = command_for("main.c", "host-gcc"),
    },
    {
      directory = f.project,
      file = "test/unit.c",
      arguments = command_for("test/unit.c", "host-gcc"),
    },
    {
      directory = f.project,
      file = "test/firmware/special.c",
      arguments = command_for("test/firmware/special.c", "host-gcc"),
    },
  })

  local params, config, notifications = invoke(f)
  local changes = params.initializationOptions.compilationDatabaseChanges
  equal("arm-none-eabi-gcc", changes[f.project .. "/main.c"].compilationCommand[1])
  equal(nil, changes[f.project .. "/test/unit.c"])
  equal("arm-none-eabi-gcc", changes[f.project .. "/test/firmware/special.c"].compilationCommand[1])
  equal(2, config._clangd_compiler_includes_status.command_count)
  equal("arm-none-eabi-gcc", config._clangd_compiler_includes_status.compiler)
  equal(0, #notifications, vim.inspect(notifications))
  f.cleanup()
end)

test("falls back after a malformed database and warns once", function()
  local f = fixture()
  mkdir(f.project .. "/build")
  write(f.project .. "/.clangd", arm_config())
  write(f.project .. "/build/compile_commands.json", "{not json")
  local params, config, notifications = invoke(f)
  equal(1, #notifications)
  truthy(notifications[1].message:find("could not load", 1, true))
  equal(2, config._clangd_compiler_includes_status.include_count)
  equal(0, config._clangd_compiler_includes_status.command_count)
  equal(4, #params.initializationOptions.fallbackFlags)
  f.cleanup()
end)

test("missing helper warns once and leaves initialization untouched", function()
  local f = fixture()
  write(f.project .. "/.clangd", arm_config())
  local initial = { fallbackFlags = { "-Wall" } }
  local params, config, notifications = invoke(f, { helper_path = f.base .. "/missing" }, initial)
  equal(initial, params.initializationOptions)
  equal(nil, config._clangd_compiler_includes_status)
  equal(1, #notifications)
  f.cleanup()
end)

test("trusts project-local compilers but rejects mismatched external paths", function()
  local f = fixture()
  mkdir(f.project .. "/build")
  local local_bin = f.project .. "/tools"
  local local_compiler = f.compiler("local-gcc", local_bin)
  local mismatch = f.compiler("arm-none-eabi-gcc", f.base .. "/other")
  write(f.project .. "/.clangd", arm_config())
  json_write(f.project .. "/build/compile_commands.json", {
    {
      directory = f.project,
      file = "one.c",
      arguments = command_for("one.c", local_compiler),
    },
    {
      directory = f.project,
      file = "two.c",
      arguments = command_for("two.c", "./tools/local-gcc"),
    },
    {
      directory = f.project,
      file = "three.c",
      arguments = command_for("three.c", mismatch),
    },
  })
  local params, config, notifications = invoke(f)
  equal(1, #notifications)
  truthy(notifications[1].message:find("does not match PATH", 1, true))
  equal(2, config._clangd_compiler_includes_status.include_count)
  equal(2, config._clangd_compiler_includes_status.command_count)
  equal(4, #params.initializationOptions.fallbackFlags)
  f.cleanup()
end)

test("aggregates failed probes into one warning and continues", function()
  local f = fixture()
  mkdir(f.project .. "/build")
  write(f.project .. "/.clangd", arm_config())
  json_write(f.project .. "/build/compile_commands.json", {
    {
      directory = f.project,
      file = "fail.c",
      arguments = command_for("fail.c", "failing-gcc"),
    },
    {
      directory = f.project,
      file = "ok.c",
      arguments = command_for("ok.c", "arm-none-eabi-gcc"),
    },
  })
  local _, config, notifications = invoke(f)
  equal(1, #notifications)
  truthy(notifications[1].message:find("deliberate failure", 1, true))
  equal(1, config._clangd_compiler_includes_status.command_count)
  f.cleanup()
end)

test("times out probes without aborting initialization", function()
  local f = fixture()
  mkdir(f.project .. "/build")
  write(f.project .. "/.clangd", arm_config())
  json_write(f.project .. "/build/compile_commands.json", {
    {
      directory = f.project,
      file = "slow.c",
      arguments = command_for("slow.c", "slow-gcc"),
    },
  })
  local params, config, notifications = invoke(f, { timeout = 20 })
  equal(1, #notifications)
  truthy(notifications[1].message:find("probe failed", 1, true))
  equal(0, config._clangd_compiler_includes_status.command_count)
  truthy(params.initializationOptions)
  f.cleanup()
end)

local failures = {}
for _, case in ipairs(tests) do
  local ok, failure = xpcall(case.callback, debug.traceback)
  if ok then
    print("ok - " .. case.name)
  else
    table.insert(failures, case.name .. "\n" .. failure)
    print("not ok - " .. case.name)
  end
end

if #failures > 0 then
  error(table.concat(failures, "\n\n"))
end

print(("%d tests passed"):format(#tests))
