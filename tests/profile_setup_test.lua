local script = debug.getinfo(1, "S").source:sub(2)
local root = script:match("^(.*)/tests/") or script:match("^(.*)tests/")
if not root or root == "" then root = "." end

if root:sub(1, 1) ~= "/" then root = assert(os.getenv("PWD")) .. "/" .. root end
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

opts.profile = "remote"
assert(not pcall(SETUP.profile.CHECK, nil, opts), "removed profile must be rejected")
assert(not pcall(SETUP.profile.INSTALL, nil, opts), "removed profile must not overwrite profile files")

local destinations = { "/.claude/CLAUDE.md", "/.codex/AGENTS.md", "/.agents/AGENTS.md", "/.omp/agent/AGENTS.md" }
local agent_home = temp .. "/agent home"
run("mkdir -p " .. quote(agent_home))
for _, scenario in ipairs({
  { expected = "/ai/CLAUDE.md" },
  { saved = "work", expected = "/ai/work/AGENTS.md" },
  { saved = "work", override = "personal", expected = "/ai/CLAUDE.md" },
  { saved = "personal", override = "work", expected = "/ai/work/AGENTS.md" },
}) do
  if scenario.saved then
    local marker = assert(io.open(agent_home .. "/.dotfiles_profile", "w"))
    marker:write(scenario.saved .. "\n")
    marker:close()
  end
  local manifest = setmetatable({
    os = setmetatable({
      getenv = function(name)
        if name == "HOME" then return agent_home end
        if name == "DOTFILES_PROFILE" then return scenario.override end
        return os.getenv(name)
      end,
    }, { __index = os }),
    envy = setmetatable({
      import = function() return { PACKAGES = {} } end,
    }, { __index = envy }),
  }, { __index = _G })
  assert(loadfile(root .. "/envy.lua", "t", manifest))()
  local links = {}
  for _, package in ipairs(manifest.PACKAGES) do
    if package.spec == "local.symlink@r0" then
      for _, link in ipairs(package.options.links) do
        for _, destination in ipairs(destinations) do
          if link.dest == agent_home .. destination then table.insert(links, link) end
        end
      end
    end
  end
  assert(#links == #destinations, "all four agent tools must receive profile instructions")
  dofile(root .. "/envy/local.symlink@r0.lua")
  local link_opts = { links = links }
  assert(not SETUP.links.CHECK(nil, link_opts), "profile changes must update agent links")
  run(SETUP.links.INSTALL(nil, link_opts))
  assert(SETUP.links.CHECK(nil, link_opts), "agent links must converge")
  for _, destination in ipairs(destinations) do
    run("cmp " .. quote(root .. scenario.expected) .. " " .. quote(agent_home .. destination))
  end
end

run("rm -rf " .. quote(temp))
print("profile setup tests passed")
