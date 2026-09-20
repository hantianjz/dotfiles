local script = debug.getinfo(1, "S").source:sub(2)
local root = script:match("^(.*)/tests/") or script:match("^(.*)tests/")
if not root or root == "" then root = "." end

local function quote(value)
  return string.format("%q", value)
end

local function run(command, check)
  return envy.run(command, { capture = true, quiet = true, check = check ~= false })
end

local function trim(value)
  return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local temp = run("mktemp -d /tmp/envy-profile-test.XXXXXX").stdout:gsub("%s+$", "")
local profile_path = temp .. "/machine profile/current"
local gitconfig_path = temp .. "/git config/local"

local opts = {
  profile = "work",
  profile_path = profile_path,
  gitconfig_path = gitconfig_path,
  git_user_email = "hjz@block.xyz",
}

dofile(root .. "/envy/local.profile@r0.lua")
assert(not SETUP.profile.CHECK(nil, opts), "missing profile files should need setup")
run(SETUP.profile.INSTALL(nil, opts))
assert(SETUP.profile.CHECK(nil, opts), "installed work profile should be current")

local profile_file = assert(io.open(profile_path, "r"))
assert(trim(profile_file:read("*a")) == "work", "profile marker should record work")
profile_file:close()

local email = trim(run("git config --file " .. quote(gitconfig_path) .. " --get user.email").stdout)
assert(email == "hjz@block.xyz", "work profile should set the work email")

run("git config --file " .. quote(gitconfig_path) .. " user.signingkey preserved-key")
opts.profile = "personal"
opts.git_user_email = "hjz@hackjumpzero.ca"
assert(not SETUP.profile.CHECK(nil, opts), "switching profiles should need setup")
run(SETUP.profile.INSTALL(nil, opts))
assert(SETUP.profile.CHECK(nil, opts), "installed personal profile should be current")

local preserved = trim(run("git config --file " .. quote(gitconfig_path) .. " --get user.signingkey").stdout)
assert(preserved == "preserved-key", "profile setup must preserve unrelated local git settings")
email = trim(run("git config --file " .. quote(gitconfig_path) .. " --get user.email").stdout)
assert(email == "hjz@hackjumpzero.ca", "personal profile should set the personal email")

run("rm -rf " .. quote(temp))
print("profile setup tests passed")
