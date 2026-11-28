-- Run from the repository root:
-- nvim --headless -u NONE -l nvim/tests/navigation_spec.lua
vim.env.TMUX = "/nonexistent/tmux"
vim.env.HERDR_ENV = "1"
vim.env.HERDR_PANE_ID = "removed-herdr-pane"
vim.env.HERDR_SOCKET_PATH = "/nonexistent/herdr"
dofile("nvim/lua/nvim_cfg.lua")

local modes
vim.keymap.set({ "n", "i", "x", "s", "o", "c", "t" }, "<F6>", function()
  modes[#modes + 1] = vim.api.nvim_get_mode().mode
end)

local function feed(keys)
  vim.api.nvim_feedkeys(vim.keycode(keys), "xt", false)
end

local function navigate(key, expected, enter, source_mode, target_mode)
  source_mode = source_mode or "n"
  modes = {}
  feed((enter or "") .. "<F6>" .. key .. "<F6><Esc>")
  assert(modes[1] == source_mode, "Expected source mode " .. source_mode .. ", got " .. tostring(modes[1]))
  assert(vim.api.nvim_get_current_win() == expected, key .. " did not select the expected window from " .. source_mode)
  if target_mode then
    assert(modes[2] == target_mode, "Expected target mode " .. target_mode .. ", got " .. tostring(modes[2]))
  end
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

for _, case in ipairs({
  { "i", "i", "i" },
  { "R", "R", "R" },
  { "v", "v" },
  { "V", "V" },
  { "<C-v>", "\22" },
  { "v<C-g>", "s" },
  { "d", "no", "n" },
  { ":let g:navigation_command_ran = 1", "c", "n" },
}) do
  local enter, source_mode, target_mode = unpack(case)
  navigate("<C-k>", top, enter, source_mode, target_mode)
  navigate("<C-k>", top, enter, source_mode, target_mode)
  navigate("<C-j>", bottom, enter, source_mode, target_mode)
end
assert(vim.g.navigation_command_ran == nil, "Pane navigation executed the command line")

local terminal = vim.api.nvim_create_buf(false, true)
vim.api.nvim_open_term(terminal, {})
vim.api.nvim_win_set_buf(bottom, terminal)
feed("i<C-k><Esc>")
assert(vim.api.nvim_get_current_win() == top, "Terminal navigation did not select the expected window")
print("Neovim navigation: all directions and modes passed")
