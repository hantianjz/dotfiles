local real_envy = envy
local root = debug.getinfo(1, "S").source:sub(2):match("^(.*)/tests/") or "."
if root:sub(1, 1) ~= "/" then root = assert(os.getenv("PWD")) .. "/" .. root end
local function quote(value) return string.format("%q", value) end
local function run(command, environment)
  return real_envy.run(command, { capture = true, quiet = true, check = false, env = environment })
end
local function put(path, value)
  local file = assert(io.open(path, "w")); assert(file:write(value)); assert(file:close())
end
local function contents(path)
  local file = assert(io.open(path)); local value = file:read("*a"); file:close(); return value
end
local temp = run("mktemp -d /tmp/neovim-setup-test.XXXXXX").stdout:gsub("%s+$", "")
local ok, failure = pcall(function()
  local function fixture(arch)
    local home = temp .. "/" .. arch .. " home"
    local commands = home .. "/commands"
    assert(run("mkdir -p " .. quote(commands)).exit_code == 0)
    put(commands .. "/curl", [[#!/bin/bash
set -eu
output=""
url=""
while (( $# )); do
  case "$1" in
    -o) output="$2"; shift 2 ;;
    https://*) url="$1"; shift ;;
    *) shift ;;
  esac
done
case "$url" in
  https://api.github.com/repos/neovim/neovim/releases/latest)
    test ! -f "$HOME/metadata-fails" || exit 22
    cat "$HOME/release.json" ;;
  "https://github.com/neovim/neovim/releases/download/$(cat "$HOME/version")/nvim-linux-$TEST_ARCH.tar.gz")
    test ! -f "$HOME/download-fails" || exit 22
    printf 'download\n' >> "$HOME/downloads"
    cp "$HOME/archive.tar.gz" "$output"
    if test -f "$HOME/corrupt-download"; then printf 'corrupt\n' >> "$output"; fi ;;
  *) exit 99 ;;
esac
]])
    put(commands .. "/nvim", "#!/bin/sh\nprintf 'native Neovim remains untouched\\n'\n")
    assert(run("chmod +x " .. quote(commands .. "/curl") .. " " .. quote(commands .. "/nvim")).exit_code == 0)
    local environment = { HOME = home, PATH = commands .. ":" .. assert(os.getenv("PATH")), TEST_ARCH = arch }
    local scope = setmetatable({ envy = { PLATFORM = "linux", ARCH = arch, run = function(command, options)
      options.env = environment
      return real_envy.run(command, options)
    end } }, { __index = _G })
    assert(loadfile(root .. "/envy/local.neovim@r0.lua", "t", scope))()
    assert(scope.USER_MANAGED and scope.SETUP.editor, "recipe must expose its user-managed editor setup")
    return home, scope.SETUP.editor, environment
  end
  local function publish(home, arch, version, runtime, binary_version)
    local name = "nvim-linux-" .. arch
    local payload = home .. "/payload/" .. name
    assert(run("rm -rf " .. quote(home .. "/payload") .. "; mkdir -p " .. quote(payload .. "/bin") .. " " ..
      quote(payload .. "/share/nvim/runtime/doc")).exit_code == 0)
    put(payload .. "/bin/nvim", "#!/bin/sh\nprintf 'NVIM " .. (binary_version or version) .. "\\nBuild type: Fixture\\n'\n")
    if runtime ~= false then put(payload .. "/share/nvim/runtime/doc/help.txt", version .. " runtime\n") end
    assert(run("chmod +x " .. quote(payload .. "/bin/nvim") .. " && tar -czf " .. quote(home .. "/archive.tar.gz") ..
      " -C " .. quote(home .. "/payload") .. " " .. quote(name)).exit_code == 0)
    local digest = assert(run("sha256sum " .. quote(home .. "/archive.tar.gz")).stdout:match("^([0-9a-f]+)"))
    put(home .. "/version", version)
    put(home .. "/release.json", string.format(
      '{"tag_name":"%s","draft":false,"prerelease":false,"assets":[{"name":"%s.tar.gz","state":"uploaded","digest":"sha256:%s"}]}',
      version, name, digest))
  end
  local function target(home)
    local result = run("readlink " .. quote(home .. "/.local/bin/nvim"))
    assert(result.exit_code == 0)
    return result.stdout:gsub("%s+$", "")
  end
  local home, setup, environment = fixture("x86_64")
  publish(home, "x86_64", "v0.12.6")
  assert(not setup.CHECK(), "native or absent Neovim must not satisfy the local release contract")
  assert(run(setup.INSTALL(), environment).exit_code == 0)
  assert(setup.CHECK(), "verified release with intact runtime must converge")
  local previous = target(home)
  local previous_runtime = previous:gsub("/bin/nvim$", "/share/nvim/runtime/doc/help.txt")
  assert(contents(previous_runtime) == "v0.12.6 runtime\n")
  local downloads = contents(home .. "/downloads")
  assert(setup.CHECK())
  assert(contents(home .. "/downloads") == downloads, "converged checks must not download the archive")
  assert(run("nvim", environment).stdout == "native Neovim remains untouched\n", "other installations must not be deleted")

  publish(home, "x86_64", "v0.13.0")
  assert(not setup.CHECK(), "latest stable metadata must detect an upgrade without a static pin")
  for _, marker in ipairs({ "metadata-fails", "download-fails", "corrupt-download" }) do
    put(home .. "/" .. marker, "")
    assert(run(setup.INSTALL(), environment).exit_code ~= 0, marker .. " must fail installation")
    assert(target(home) == previous, marker .. " must preserve the current executable")
    assert(contents(previous_runtime) == "v0.12.6 runtime\n", marker .. " must preserve the current runtime")
    assert(os.remove(home .. "/" .. marker))
  end
  local stable_metadata = contents(home .. "/release.json")
  for _, metadata in ipairs({
    stable_metadata:gsub('"prerelease":false', '"prerelease":true'),
    stable_metadata:gsub('"draft":false', '"draft":true'),
    stable_metadata:gsub('v0%.13%.0', 'nightly'),
    stable_metadata:gsub('sha256:[0-9a-f]+', 'sha256:invalid'),
    '{"tag_name":"v0.13.0","draft":false,"prerelease":false,"assets":[]}',
  }) do
    put(home .. "/release.json", metadata)
    assert(not setup.CHECK(), "invalid or non-stable metadata must not satisfy setup")
    assert(run(setup.INSTALL(), environment).exit_code ~= 0, "invalid release metadata must fail closed")
    assert(target(home) == previous)
  end
  publish(home, "x86_64", "v0.13.0", false)
  assert(run(setup.INSTALL(), environment).exit_code ~= 0, "missing runtime must fail before activation")
  assert(target(home) == previous)
  publish(home, "x86_64", "v0.13.0", true, "v0.12.6")
  assert(run(setup.INSTALL(), environment).exit_code ~= 0, "wrong binary version must fail before activation")
  assert(target(home) == previous)
  publish(home, "x86_64", "v0.13.0")
  assert(run(setup.INSTALL(), environment).exit_code == 0)
  assert(setup.CHECK())
  assert(target(home) ~= previous, "successful upgrade must activate the new release")
  assert(contents(previous_runtime) == "v0.12.6 runtime\n", "old runtime must remain usable by running editors")

  home, setup, environment = fixture("arm64")
  publish(home, "arm64", "v0.12.6")
  assert(run("mkdir -p " .. quote(home .. "/.local/bin")).exit_code == 0)
  put(home .. "/.local/bin/nvim", "unrelated installation\n")
  assert(run(setup.INSTALL(), environment).exit_code ~= 0, "unrelated local installation must require relocation")
  assert(contents(home .. "/.local/bin/nvim") == "unrelated installation\n")
  assert(os.remove(home .. "/.local/bin/nvim"))
  assert(run("ln -s " .. quote(home .. "/commands/nvim") .. " " .. quote(home .. "/.local/bin/nvim")).exit_code == 0)
  assert(run(setup.INSTALL(), environment).exit_code ~= 0, "unrelated symlinks must require relocation")
  assert(run(quote(home .. "/.local/bin/nvim"), environment).stdout == "native Neovim remains untouched\n")
  assert(os.remove(home .. "/.local/bin/nvim"))
  assert(run(setup.INSTALL(), environment).exit_code == 0, "arm64 must use its official archive")
  assert(setup.CHECK())
end)
assert(run("rm -rf " .. quote(temp)).exit_code == 0)
assert(ok, failure)
print("Neovim setup tests passed: stable discovery, checksums, upgrades, runtime, and safe failure")
