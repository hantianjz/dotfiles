-- @envy schema "1"
IDENTITY = "local.binstall@r0"

local hashes = {
  x86_64 = "9e0e064f189a9abb9f8df5fb93c3c810ef5cc19e7212d998c7a64c9e4d3527d5",
  arm64 = "a235250cd684af9bf1e3a1e4c216b1d36e6c553553d5d789744f27689d81c2d6",
}

FETCH = function()
  assert(envy.PLATFORM == "linux" and hashes[envy.ARCH], "cargo-binstall requires Linux x86_64 or arm64")
  local arch = envy.ARCH == "arm64" and "aarch64" or "x86_64"
  return {
    source = "https://github.com/cargo-bins/cargo-binstall/releases/download/v1.26.2/cargo-binstall-" ..
      arch .. "-unknown-linux-musl.tgz",
    sha256 = hashes[envy.ARCH],
  }
end

STAGE = { strip = 0 }

SETUP = { tools = {
  CHECK = function(pkg_dir)
    return envy.run('test -x "$HOME/.local/bin/cargo-binstall" && cmp -s ' ..
      string.format("%q", pkg_dir .. "/cargo-binstall") .. ' "$HOME/.local/bin/cargo-binstall"',
      { capture = true, quiet = true, check = false }).exit_code == 0
  end,
  INSTALL = function(pkg_dir)
    return 'install -d "$HOME/.local/bin" && install -m 755 ' ..
      string.format("%q", pkg_dir .. "/cargo-binstall") .. ' "$HOME/.local/bin/cargo-binstall"'
  end,
} }
