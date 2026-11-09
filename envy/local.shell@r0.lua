-- @envy schema "1"
IDENTITY = "local.shell@r0"
USER_MANAGED = true

DEPENDENCIES = {
  { spec = "local.system_packages@r0", setup = { "packages" }, needed_by = "check" },
  { spec = "local.symlink@r0", setup = { "links" }, needed_by = "check" },
}

local check = function(pkg_dir, opts)
  if opts.check then
    local res = envy.run(opts.check, { capture = true, quiet = true, check = false })
    return res.exit_code == 0
  end
  return false
end

local install = function(pkg_dir, opts)
  return opts.install
end

SETUP = { command = { CHECK = check, INSTALL = install } }
