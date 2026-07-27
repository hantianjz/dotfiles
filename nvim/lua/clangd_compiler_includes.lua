local M = {}

local uv = vim.uv or vim.loop

local cpu_flag_names = {
  ["-mabi"] = true,
  ["-march"] = true,
  ["-mcpu"] = true,
  ["-mfpu"] = true,
  ["-mfloat-abi"] = true,
  ["-mtune"] = true,
  ["--sysroot"] = true,
  ["-isysroot"] = true,
}

local standalone_cpu_flags = {
  ["-mthumb"] = true,
  ["-mno-thumb"] = true,
  ["-mthumb-interwork"] = true,
  ["-nostdinc"] = true,
  ["-nostdinc++"] = true,
}

local function trim(value)
  return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function strip_comment(line)
  local quote
  local escaped = false
  for index = 1, #line do
    local char = line:sub(index, index)
    if escaped then
      escaped = false
    elseif char == "\\" and quote == '"' then
      escaped = true
    elseif quote then
      if char == quote then
        quote = nil
      end
    elseif char == "'" or char == '"' then
      quote = char
    elseif char == "#" then
      return line:sub(1, index - 1)
    end
  end
  return line
end

local function unquote(value)
  value = trim(value)
  local first = value:sub(1, 1)
  if #value >= 2 and (first == "'" or first == '"') and value:sub(-1) == first then
    value = value:sub(2, -2)
    if first == '"' then
      value = value:gsub('\\"', '"'):gsub("\\\\", "\\")
    else
      value = value:gsub("''", "'")
    end
  end
  return value
end

local function split_inline_list(value)
  value = trim(value)
  if value:sub(1, 1) ~= "[" or value:sub(-1) ~= "]" then
    return { unquote(value) }
  end

  local result = {}
  local current = {}
  local quote
  local escaped = false
  for index = 2, #value - 1 do
    local char = value:sub(index, index)
    if escaped then
      table.insert(current, char)
      escaped = false
    elseif char == "\\" and quote == '"' then
      table.insert(current, char)
      escaped = true
    elseif quote then
      table.insert(current, char)
      if char == quote then
        quote = nil
      end
    elseif char == "'" or char == '"' then
      quote = char
      table.insert(current, char)
    elseif char == "," then
      table.insert(result, unquote(table.concat(current)))
      current = {}
    else
      table.insert(current, char)
    end
  end
  table.insert(result, unquote(table.concat(current)))
  return result
end

local list_keys = {
  Add = "add",
  PathExclude = "path_exclude",
  PathMatch = "path_match",
}

local function parse_fragment(contents)
  local parsed = {
    add = {},
    path_exclude = {},
    path_match = {},
  }
  local active_list
  local list_indent = -1

  for raw_line in (contents .. "\n"):gmatch("(.-)\n") do
    local line = strip_comment(raw_line)
    local indent = #(line:match("^%s*") or "")
    local text = trim(line)

    if text ~= "" then
      local key, value = text:match("^([%w]+):%s*(.*)$")
      if key == "Compiler" and value ~= "" then
        parsed.compiler = unquote(value)
      elseif key == "CompilationDatabase" and value ~= "" then
        parsed.compilation_database = unquote(value)
      elseif list_keys[key] then
        active_list = list_keys[key]
        list_indent = indent
        if value ~= "" then
          vim.list_extend(parsed[active_list], split_inline_list(value))
          active_list = nil
        end
      elseif active_list and indent > list_indent then
        local item = text:match("^%-%s*(.+)$")
        if item then
          table.insert(parsed[active_list], unquote(item))
        end
      elseif active_list and indent <= list_indent then
        active_list = nil
      end
    end
  end

  return parsed
end

local function parse_clangd(contents)
  local fragments = {}
  local lines = {}

  local function finish_fragment()
    table.insert(fragments, parse_fragment(table.concat(lines, "\n")))
    lines = {}
  end

  for raw_line in (contents .. "\n"):gmatch("(.-)\n") do
    if trim(strip_comment(raw_line)) == "---" then
      finish_fragment()
    else
      table.insert(lines, raw_line)
    end
  end
  finish_fragment()
  return fragments
end

local function relative_to_root(path, root)
  local normalized_root = vim.fs.normalize(root):gsub("/$", "")
  local normalized_file = vim.fs.normalize(path)
  if normalized_file == normalized_root then
    return ""
  end
  if normalized_file:sub(1, #normalized_root + 1) == normalized_root .. "/" then
    return normalized_file:sub(#normalized_root + 2)
  end
  return normalized_file
end

local function compile_conditions(fragments, failures)
  for index, fragment in ipairs(fragments) do
    fragment._path_match = {}
    fragment._path_exclude = {}
    for source, destination in pairs({
      path_match = "_path_match",
      path_exclude = "_path_exclude",
    }) do
      for _, pattern in ipairs(fragment[source]) do
        local ok, regex = pcall(vim.regex, "\\v^(" .. pattern .. ")$")
        if ok then
          table.insert(fragment[destination], regex)
        else
          table.insert(failures, ("ignored invalid If.%s regex in fragment %d: %s"):format(
            source == "path_match" and "PathMatch" or "PathExclude",
            index,
            pattern
          ))
        end
      end
    end
  end
end

local function any_regex_matches(regexes, path)
  for _, regex in ipairs(regexes) do
    if regex:match_str(path) ~= nil then
      return true
    end
  end
  return false
end

local function fragment_matches(fragment, relative_path)
  if relative_path == nil then
    return #fragment.path_match == 0 and #fragment.path_exclude == 0
  end
  if #fragment.path_match > 0 and not any_regex_matches(fragment._path_match, relative_path) then
    return false
  end
  if #fragment.path_exclude > 0 and any_regex_matches(fragment._path_exclude, relative_path) then
    return false
  end
  return true
end

local function effective_config(fragments, file, root)
  local result = { add = {} }
  local relative_path = file and relative_to_root(file, root) or nil
  for _, fragment in ipairs(fragments) do
    if fragment_matches(fragment, relative_path) then
      vim.list_extend(result.add, fragment.add)
      result.compiler = fragment.compiler or result.compiler
      result.compilation_database = fragment.compilation_database or result.compilation_database
    end
  end
  return result
end

local function shell_split(command)
  local result = {}
  local current = {}
  local quote
  local escaped = false
  local started = false

  local function finish()
    if started then
      table.insert(result, table.concat(current))
      current = {}
      started = false
    end
  end

  for index = 1, #command do
    local char = command:sub(index, index)
    if escaped then
      table.insert(current, char)
      escaped = false
      started = true
    elseif quote == "'" then
      if char == "'" then
        quote = nil
      else
        table.insert(current, char)
      end
      started = true
    elseif quote == '"' then
      if char == '"' then
        quote = nil
      elseif char == "\\" then
        local next_char = command:sub(index + 1, index + 1)
        if next_char == '"' or next_char == "\\" or next_char == "$" or next_char == "`" then
          escaped = true
        else
          table.insert(current, char)
        end
      else
        table.insert(current, char)
      end
      started = true
    elseif char == "'" or char == '"' then
      quote = char
      started = true
    elseif char:match("%s") then
      finish()
    elseif char == "\\" then
      escaped = true
      started = true
    else
      table.insert(current, char)
      started = true
    end
  end

  if quote or escaped then
    return nil, "unterminated quote or escape in compilation command"
  end
  finish()
  return result
end

local function normalized_path(path)
  return uv.fs_realpath(path)
end

local function path_is_within(path, root)
  return path == root or path:sub(1, #root + 1) == root .. "/"
end

local function resolve_compiler(compiler, root, working_directory)
  if not compiler or compiler == "" then
    return nil, "empty compiler"
  end

  local invocation
  local requested
  if compiler:find("/", 1, true) then
    local compiler_path = compiler
    if compiler:sub(1, 1) ~= "/" then
      compiler_path = (working_directory or root) .. "/" .. compiler
    end
    invocation = vim.fs.normalize(compiler_path)
    requested = normalized_path(invocation)
  else
    local executable = vim.fn.exepath(compiler)
    invocation = executable ~= "" and vim.fs.normalize(executable) or nil
    requested = invocation and normalized_path(invocation) or nil
  end

  if not requested then
    return nil, ("compiler is not available through PATH: %s"):format(compiler)
  end

  local root_real = normalized_path(root) or root
  if path_is_within(requested, root_real) then
    if vim.fn.executable(invocation) ~= 1 then
      return nil, ("project-local compiler is not executable: %s"):format(compiler)
    end
    return invocation
  end

  local basename = vim.fs.basename(compiler)
  local from_path = vim.fn.exepath(basename)
  from_path = from_path ~= "" and normalized_path(from_path) or nil
  if not from_path or from_path ~= requested then
    return nil, ("compiler does not match PATH executable: %s"):format(compiler)
  end

  return invocation
end

local function extract_probe_flags(arguments, config_flags)
  local combined = {}
  vim.list_extend(combined, config_flags or {})
  vim.list_extend(combined, arguments or {})

  local result = {}
  local seen = {}
  local function add_flag(argument, value)
    local signature = value and (argument .. "\0" .. value) or argument
    if seen[signature] then
      return
    end
    seen[signature] = true
    table.insert(result, argument)
    if value then
      table.insert(result, value)
    end
  end

  local index = 1
  while index <= #combined do
    local argument = combined[index]
    if standalone_cpu_flags[argument] then
      add_flag(argument)
    else
      local name = argument:match("^([^=]+)=")
      if name and cpu_flag_names[name] then
        add_flag(argument)
      elseif cpu_flag_names[argument] and combined[index + 1] then
        add_flag(argument, combined[index + 1])
        index = index + 1
      end
    end
    index = index + 1
  end
  return result
end

local fallback_driver_names = {
  ["cc"] = true,
  ["c++"] = true,
  ["gcc"] = true,
  ["g++"] = true,
  ["clang"] = true,
  ["clang++"] = true,
  ["ccache"] = true,
  ["env"] = true,
  ["hermit"] = true,
  ["sccache"] = true,
}

local function probe_compiler(command, fallback_compiler, target)
  if command.compiler then
    return command.compiler, 3
  end
  local compiler = command.arguments[1]
  local basename = compiler and vim.fs.basename(compiler) or ""
  if fallback_driver_names[basename] then
    return fallback_compiler, 0
  end
  if basename:find(target .. "-", 1, true) == 1 then
    return compiler, 2
  end
  return compiler or fallback_compiler, 1
end

local cpp_extensions = {
  cc = true,
  cp = true,
  cpp = true,
  cxx = true,
  cxxm = true,
  hpp = true,
  hxx = true,
  ["C"] = true,
}

local function command_language(arguments, file)
  for index, argument in ipairs(arguments) do
    if argument == "-x" and arguments[index + 1] then
      return arguments[index + 1]
    end
    local language = argument:match("^%-x(.+)$")
    if language then
      return language
    end
  end
  local extension = file:match("%.([^./]+)$")
  return cpp_extensions[extension] and "c++" or "c"
end

local function insert_includes(arguments, includes)
  local result = vim.deepcopy(arguments)
  local insertion = #result + 1
  for index, argument in ipairs(result) do
    if argument == "--" then
      insertion = index
      break
    end
  end

  local additions = {}
  for _, include in ipairs(includes) do
    table.insert(additions, "-isystem")
    table.insert(additions, include)
  end
  for index = #additions, 1, -1 do
    table.insert(result, insertion, additions[index])
  end
  return result
end

local function read_file(path)
  local file, error_message = io.open(path, "r")
  if not file then
    return nil, error_message
  end
  local contents = file:read("*a")
  file:close()
  return contents
end

local function decode_database(path)
  local contents, read_error = read_file(path)
  if not contents then
    return nil, read_error
  end
  local ok, decoded = pcall(vim.json.decode, contents)
  if not ok or type(decoded) ~= "table" or not vim.islist(decoded) then
    return nil, ok and "database is not a JSON array" or decoded
  end
  return decoded
end

local function absolute_path(path, base)
  if path:sub(1, 1) == "/" then
    return vim.fs.normalize(path)
  end
  return vim.fs.normalize(base .. "/" .. path)
end

local function root_from(params, config)
  if config.root_dir and config.root_dir ~= "" then
    return config.root_dir
  end
  local uri = params.rootUri or (params.workspaceFolders and params.workspaceFolders[1] and params.workspaceFolders[1].uri)
  if uri then
    return vim.uri_to_fname(uri)
  end
  return params.rootPath
end

local function warn_once(messages)
  if #messages == 0 then
    return
  end
  vim.schedule(function()
    vim.notify(
      "clangd compiler include discovery:\n- " .. table.concat(messages, "\n- "),
      vim.log.levels.WARN
    )
  end)
end

function M.make_before_init(options)
  vim.validate("options", options, "table")
  vim.validate("options.helper_path", options.helper_path, "string")
  local target = options.target or "arm-none-eabi"
  local fallback_compiler = options.fallback_compiler or "arm-none-eabi-gcc"
  local timeout = options.timeout or 5000

  return function(params, config)
    local root = root_from(params, config)
    config._clangd_compiler_includes_status = nil
    if not root then
      return
    end

    local clangd_path = root .. "/.clangd"
    local contents = read_file(clangd_path)
    if not contents then
      return
    end

    local fragments = parse_clangd(contents)
    local target_flag = "--target=" .. target
    local has_target = false
    for _, fragment in ipairs(fragments) do
      if vim.tbl_contains(fragment.add, target_flag) then
        has_target = true
        break
      end
    end
    if not has_target then
      return
    end

    local failures = {}
    compile_conditions(fragments, failures)

    local commands = {}
    local database_directories = {}
    local database_seen = {}
    local function add_database_directory(directory)
      if directory and not database_seen[directory] then
        database_seen[directory] = true
        table.insert(database_directories, directory)
      end
    end

    local has_explicit_target_database = false
    for _, fragment in ipairs(fragments) do
      if vim.tbl_contains(fragment.add, target_flag) and fragment.compilation_database then
        has_explicit_target_database = true
        local value = fragment.compilation_database
        if value == "Ancestors" then
          add_database_directory(root)
        elseif value ~= "None" then
          add_database_directory(absolute_path(value, root))
        end
      end
    end

    if not has_explicit_target_database then
      local unconditional = effective_config(fragments, nil, root)
      if unconditional.compilation_database == nil or unconditional.compilation_database == "Ancestors" then
        add_database_directory(root)
      end
      for _, fragment in ipairs(fragments) do
        local value = fragment.compilation_database
        local directory
        if value == "Ancestors" then
          directory = root
        elseif value and value ~= "None" then
          directory = absolute_path(value, root)
        end
        add_database_directory(directory)
      end
    end
    if #database_directories == 0 then
      table.insert(database_directories, root)
    end

    for _, database_directory in ipairs(database_directories) do
      local database_path = database_directory .. "/compile_commands.json"
      local database, database_error = decode_database(database_path)
      if not database then
        table.insert(failures, ("could not load %s: %s"):format(database_path, database_error))
        database = {}
      end

      for index, entry in ipairs(database) do
        if type(entry) ~= "table" or type(entry.file) ~= "string" or type(entry.directory) ~= "string" then
          table.insert(failures, ("ignored malformed compilation database entry %d in %s"):format(index, database_path))
        else
          local working_directory = absolute_path(entry.directory, root)
          local file = absolute_path(entry.file, working_directory)
          local effective = effective_config(fragments, file, root)
          local effective_database
          if effective.compilation_database == nil or effective.compilation_database == "Ancestors" then
            effective_database = root
          elseif effective.compilation_database ~= "None" then
            effective_database = absolute_path(effective.compilation_database, root)
          end

          if effective_database == database_directory and vim.tbl_contains(effective.add, target_flag) then
            local arguments = entry.arguments
            local split_error
            if type(arguments) ~= "table" and type(entry.command) == "string" then
              arguments, split_error = shell_split(entry.command)
            end
            if type(arguments) ~= "table" or #arguments == 0 then
              table.insert(
                failures,
                ("ignored command for %s: %s"):format(entry.file, split_error or "missing arguments")
              )
            else
              table.insert(commands, {
                add = effective.add,
                arguments = arguments,
                compiler = effective.compiler,
                directory = working_directory,
                file = file,
              })
            end
          end
        end
      end
    end

    local unique_commands = {}
    local command_indexes = {}
    for _, command in ipairs(commands) do
      command.probe_compiler, command._compiler_score = probe_compiler(command, fallback_compiler, target)
      local existing_index = command_indexes[command.file]
      if not existing_index then
        table.insert(unique_commands, command)
        command_indexes[command.file] = #unique_commands
      elseif command._compiler_score > unique_commands[existing_index]._compiler_score then
        unique_commands[existing_index] = command
      end
    end
    commands = unique_commands

    if #commands == 0 then
      local fallback_config = effective_config(fragments, nil, root)
      if vim.tbl_contains(fallback_config.add, target_flag) then
        table.insert(commands, {
          add = fallback_config.add,
          arguments = { fallback_compiler },
          compiler = fallback_config.compiler,
          directory = root,
          file = root .. "/__clangd_fallback__.c",
          fallback_only = true,
          probe_compiler = fallback_config.compiler or fallback_compiler,
        })
      end
    end

    local helper = normalized_path(options.helper_path)
    if not helper or vim.fn.executable(helper) ~= 1 then
      table.insert(failures, ("include helper is missing or not executable: %s"):format(options.helper_path))
      warn_once(failures)
      return
    end

    local probes = {}
    local compiler_names = {}
    local include_union = {}
    local include_seen = {}
    local overridden = 0
    local init_options = params.initializationOptions or {}
    params.initializationOptions = init_options
    local changes = init_options.compilationDatabaseChanges or {}
    init_options.compilationDatabaseChanges = changes

    for _, command in ipairs(commands) do
      local compiler = command.probe_compiler
      local resolved, resolve_error = resolve_compiler(compiler, root, command.directory)
      if not resolved then
        table.insert(failures, resolve_error)
      else
        local flags = extract_probe_flags(command.arguments, command.add)
        local language = command_language(command.arguments, command.file)
        local signature = table.concat(vim.list_extend({ resolved, language }, vim.deepcopy(flags)), "\0")
        local includes = probes[signature]
        if includes == nil then
          local probe_command = { helper, resolved }
          vim.list_extend(probe_command, flags)
          vim.list_extend(probe_command, { "-x", language })
          local process = vim.system(probe_command, { text = true })
          local result = process:wait(timeout)
          local timed_out = result == nil
          if timed_out then
            process:kill(9)
            result = process:wait() or { code = 124, stdout = "", stderr = "" }
          end
          includes = {}
          if timed_out or result.code ~= 0 then
            local detail = trim(result.stderr or "")
            if timed_out or result.code == 124 then
              detail = "timed out"
            elseif detail == "" then
              detail = "exit code " .. tostring(result.code)
            end
            table.insert(failures, ("%s probe failed: %s"):format(vim.fs.basename(resolved), detail))
          else
            local seen = {}
            for line in (result.stdout or ""):gmatch("[^\r\n]+") do
              local path = normalized_path(trim(line))
              local stat = path and uv.fs_stat(path)
              if stat and stat.type == "directory" and not seen[path] then
                seen[path] = true
                table.insert(includes, path)
              end
            end
            if #includes == 0 then
              table.insert(failures, ("%s probe returned no valid include directories"):format(vim.fs.basename(resolved)))
            end
          end
          probes[signature] = includes
        end

        compiler_names[vim.fs.basename(resolved)] = true
        for _, include in ipairs(includes) do
          if not include_seen[include] then
            include_seen[include] = true
            table.insert(include_union, include)
          end
        end

        if not command.fallback_only and #includes > 0 then
          local existing = changes[command.file]
          local base_arguments = existing and existing.compilationCommand or command.arguments
          changes[command.file] = {
            workingDirectory = (existing and existing.workingDirectory) or command.directory,
            compilationCommand = insert_includes(base_arguments, includes),
          }
          overridden = overridden + 1
        end
      end
    end

    if #include_union > 0 then
      init_options.fallbackFlags = insert_includes(init_options.fallbackFlags or {}, include_union)
    end

    local compiler_list = vim.tbl_keys(compiler_names)
    table.sort(compiler_list)
    config._clangd_compiler_includes_status = {
      compiler = table.concat(compiler_list, ", "),
      include_count = #include_union,
      command_count = overridden,
    }
    warn_once(failures)
  end
end

M._parse_clangd = parse_clangd
M._shell_split = shell_split
M._insert_includes = insert_includes

return M
