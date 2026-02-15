IDENTITY = "local.shell@r0"

CHECK = function(tmp_dir, opts)
  if opts.check then
    local res = envy.run(opts.check, { capture = true, quiet = true })
    return res.exit_code == 0
  end
  return false
end

INSTALL = function(install_dir, stage_dir, fetch_dir, tmp_dir, opts)
  return opts.install
end
