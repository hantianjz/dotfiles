-- @envy schema "1"
IDENTITY = "local.herdr@r0"
USER_MANAGED = true

DEPENDENCIES = {
  { spec = "local.system_packages@r0", setup = { "packages" }, needed_by = "check" },
  { spec = "local.symlink@r0", setup = { "links" }, needed_by = "check" },
}

local home = assert(os.getenv("HOME"))
local function quote(value) return string.format("%q", value) end
local function succeeds(command)
  return envy.run(command, { capture = true, quiet = true, check = false }).exit_code == 0
end
local function herdr_command()
  return succeeds("command -v herdr") and "herdr" or quote(home .. "/.local/bin/herdr")
end
local missing = {}

SETUP = {
  cli = {
    PLATFORMS = { "linux" },
    CHECK = function()
      return succeeds("command -v herdr >/dev/null 2>&1 || test -x " .. quote(home .. "/.local/bin/herdr"))
    end,
    INSTALL = "set -o pipefail\ncurl -fsSL https://herdr.dev/install.sh | sh",
  },
  plugins = {
    DEPENDS = { "cli" },
    CHECK = function(pkg_dir, opts)
      missing = {}
      for _, plugin in ipairs(opts.plugins) do
        local owner, repo = plugin:match("^([^/]+)/([^/]+)$")
        assert(owner, "invalid Herdr plugin: " .. plugin)
        -- Inspect registered local installs, not a running server's protocol.
        if not succeeds(string.format([[
jq -r --arg owner %s --arg repo %s '
  .[] | select(.source.kind == "github" and .source.owner == $owner and .source.repo == $repo)
  | .plugin_root // empty
' %s 2>/dev/null | {
  while IFS= read -r root; do
    if test -d "$root"; then exit 0; fi
  done
  exit 1
}
]], quote(owner), quote(repo), quote(home .. "/.config/herdr/plugins.json"))) then
          table.insert(missing, plugin)
        end
      end
      return #missing == 0
    end,
    INSTALL = function()
      for _, plugin in ipairs(missing) do
        envy.run(herdr_command() .. " plugin install " .. quote(plugin) .. " -y")
      end
    end,
  },
}
