IDENTITY = "local.rustup@r0"

CHECK = function(tmp_dir, opts)
  local res = envy.run("rustup --version", { capture = true, quiet = true })
  return res.exit_code == 0
end

INSTALL = function(install_dir, stage_dir, fetch_dir, tmp_dir, opts)
  return "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
end
