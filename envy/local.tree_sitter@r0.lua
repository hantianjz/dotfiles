-- @envy schema "1"
IDENTITY = "local.tree_sitter@r0"
PLATFORMS = { "linux-x86_64", "linux-arm64" }

local artifacts = {
  x86_64 = { "x64", "b4233ecc4f0e648d6d8ccc4bac96c00c712ca1a5eb1e0ca7197d29b750bffa6d" },
  arm64 = { "arm64", "4598875d129dfef384b3d78da329b766f151c2f827404fb5f3363a135935d0d3" },
}

FETCH = function()
  assert(envy.PLATFORM == "linux", "Tree-sitter release requires Linux")
  local artifact = assert(artifacts[envy.ARCH], "unsupported Tree-sitter release architecture")
  return {
    source = "https://github.com/tree-sitter/tree-sitter/releases/download/v0.27.2/tree-sitter-cli-linux-" ..
      artifact[1] .. ".zip",
    sha256 = artifact[2],
  }
end
STAGE = { strip = 0 }

SETUP = { tools = {
  CHECK = function(pkg_dir)
    return envy.run('test -x "$HOME/.local/bin/tree-sitter" && cmp -s ' ..
      string.format("%q", pkg_dir .. "/tree-sitter") .. ' "$HOME/.local/bin/tree-sitter"',
      { capture = true, quiet = true, check = false }).exit_code == 0
  end,
  INSTALL = function(pkg_dir)
    return 'install -d "$HOME/.local/bin" && install -m 755 ' ..
      string.format("%q", pkg_dir .. "/tree-sitter") .. ' "$HOME/.local/bin/tree-sitter"'
  end,
} }
