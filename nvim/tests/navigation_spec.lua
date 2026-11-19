-- Run from the repository root:
-- nvim --headless -u NONE -l nvim/tests/navigation_spec.lua
vim.env.TMUX = "/nonexistent/tmux"
vim.env.HERDR_ENV = "1"
vim.env.HERDR_PANE_ID = "removed-herdr-pane"
vim.env.HERDR_SOCKET_PATH = "/nonexistent/herdr"
dofile("nvim/lua/nvim_cfg.lua")

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
navigate("<C-h>", left)
navigate("<C-l>", right)
navigate("<C-l>", right)

vim.cmd("only")
vim.cmd("split")
vim.cmd("wincmd k")
local top = vim.api.nvim_get_current_win()
vim.cmd("wincmd j")
local bottom = vim.api.nvim_get_current_win()
navigate("<C-k>", top)
navigate("<C-k>", top)
navigate("<C-j>", bottom)
navigate("<C-j>", bottom)
print("Neovim navigation: all four directions passed")
