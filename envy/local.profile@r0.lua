-- @envy schema "1"
IDENTITY = "local.profile@r0"
USER_MANAGED = true

local function quote(value)
  return string.format("%q", value)
end

local function trim(value)
  return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function parent_dir(path)
  return path:match("(.+)/[^/]+$")
end

local function validate(opts)
  assert(opts.profile == "personal" or opts.profile == "work", "profile must be personal or work")
  assert(opts.profile_path and opts.profile_path ~= "", "profile_path is required")
  assert(opts.gitconfig_path and opts.gitconfig_path ~= "", "gitconfig_path is required")
  assert(opts.git_user_email and opts.git_user_email ~= "", "git_user_email is required")
end

local function read_profile(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local line = file:read("*l")
  file:close()
  return trim(line)
end

local function read_git_email(path)
  local res = envy.run("git config --file " .. quote(path) .. " --get user.email", {
    capture = true,
    quiet = true,
    check = false,
  })
  if res.exit_code ~= 0 then
    return nil
  end
  return trim(res.stdout)
end

local check = function(pkg_dir, opts)
  validate(opts)
  return read_profile(opts.profile_path) == opts.profile
    and read_git_email(opts.gitconfig_path) == opts.git_user_email
end

local install = function(pkg_dir, opts)
  validate(opts)
  local cmds = {}
  local profile_parent = parent_dir(opts.profile_path)
  local gitconfig_parent = parent_dir(opts.gitconfig_path)
  if profile_parent then
    table.insert(cmds, "mkdir -p " .. quote(profile_parent))
  end
  if gitconfig_parent and gitconfig_parent ~= profile_parent then
    table.insert(cmds, "mkdir -p " .. quote(gitconfig_parent))
  end
  table.insert(cmds, "printf '%s\\n' " .. quote(opts.profile) .. " > " .. quote(opts.profile_path))
  table.insert(cmds, "git config --file " .. quote(opts.gitconfig_path) .. " user.email " .. quote(opts.git_user_email))
  return table.concat(cmds, " && ")
end

SETUP = { profile = { CHECK = check, INSTALL = install } }
