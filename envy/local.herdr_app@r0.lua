-- @envy schema "1"
-- Keep the same conflict and adoption policy as other dotfiles.
local directory = assert(debug.getinfo(1, "S").source:sub(2):match("^(.*)/"))
dofile(directory .. "/local.symlink@r0.lua")
IDENTITY = "local.herdr_app@r0"
