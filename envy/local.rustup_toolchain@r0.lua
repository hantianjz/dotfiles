IDENTITY = "local.rustup_toolchain@r0"

DEPENDENCIES = { recipe = "local.rustup@r0", source = "local.rustup@r0.lua" }

CHECK = function(tmp_dir, opts)
  local res = envy.run("rustup default", { capture = true, quiet = true })
  if res.exit_code ~= 0 then
    return false
  end
  return res.stdout:match("^" .. opts.toolchain) ~= nil
end

INSTALL = function(install_dir, stage_dir, fetch_dir, tmp_dir, opts)
  return "rustup default " .. opts.toolchain
end
