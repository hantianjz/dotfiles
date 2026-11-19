-- Run from the repository root with installed Neovim plugins:
-- env -u TMUX -u HERDR_ENV -u HERDR_PANE_ID -u HERDR_SOCKET_PATH nvim --headless -u NONE -l nvim/tests/navigation_spec.lua
vim.opt.loadplugins = true
vim.opt.runtimepath:prepend(vim.fn.stdpath("data") .. "/lazy/lazy.nvim")
require("lazy").setup({
  spec = dofile("nvim/lua/plugins/tmux.lua"),
  install = { missing = false },
  checker = { enabled = false },
  change_detection = { enabled = false },
})

local function navigate(key, expected)
  local input = vim.api.nvim_replace_termcodes(key, true, false, true)
  vim.api.nvim_feedkeys(input, "xt", false)
  assert(vim.api.nvim_get_current_win() == expected, key .. " did not select the expected window")
end

vim.cmd("vsplit")
vim.cmd("wincmd h")
local left = vim.api.nvim_get_current_win()
vim.cmd("wincmd l")
local right = vim.api.nvim_get_current_win()
navigate("<C-h>", left)
navigate("<C-l>", right)

vim.cmd("only")
vim.cmd("split")
vim.cmd("wincmd k")
local top = vim.api.nvim_get_current_win()
vim.cmd("wincmd j")
local bottom = vim.api.nvim_get_current_win()
navigate("<C-k>", top)
navigate("<C-j>", bottom)
print("Neovim navigation: all four directions passed")
