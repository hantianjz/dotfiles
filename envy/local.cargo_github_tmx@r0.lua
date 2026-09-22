-- @envy schema "1"
IDENTITY = "local.cargo_github_tmx@r0"
USER_MANAGED = true

DEPENDENCIES = { {
  spec = "local.rustup_toolchain@r0",
  source = "local.rustup_toolchain@r0.lua",
  setup = { "toolchain" },
  options = { toolchain = "stable" },
  needed_by = "check",
}, {
  spec = "envy.github@r0",
  bundle = {
    identity = "envy.package-specs@r7",
    source = "https://github.com/envy-package-manager/package-specs.git",
    -- envy git-resolve https://github.com/envy-package-manager/package-specs main
    ref = "aa8f5d728dc94f5a56084fb3c2a9ed74c51e71e1",
  },
  options = {
    repo = "hantianjz/tmx",
    -- envy git-resolve https://github.com/hantianjz/tmx main
    ref = "87b1e7b150b0c2f60f1d210b9dbd6873b7f1cb84",
    dest = "tmx",
  },
  needed_by = "check",
} }

local cargo = envy.loadenv("cargo_github_tool")

SETUP = { tool = cargo.setup("tmx", "tmx") }
