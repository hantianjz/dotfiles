return {
  "stevearc/oil.nvim",
  cmd = "Oil",
  keys = {
    { "-", "<cmd>Oil<cr>", desc = "Open parent directory" }
  },
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    view_options = {
      show_hidden = true
    },
    keymaps = {
      ["g?"] = { "actions.show_help", mode = "n" },
      ["<CR>"] = "actions.select",
      ["<esc><esc>"] = { "actions.close", mode = "n" },
      ["<C-r>"] = "actions.refresh",
      ["-"] = { "actions.parent", mode = "n" },
      ["_"] = { "actions.open_cwd", mode = "n" },
      ["gs"] = { "actions.change_sort", mode = "n" },
    },
    use_default_keymaps = false,
  },
}
