return {
  "stevearc/oil.nvim",
  cmd = "Oil",
  lazy = false,
  keys = {
    { "-", "<cmd>Oil<cr>", desc = "Open parent directory" }
  },
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("oil").setup({
      default_file_explorer = true,
      watch_for_changes = true,
      view_options = {
        show_hidden = true
      },
      keymaps = {
        ["g?"] = { "actions.show_help", mode = "n" },
        ["<CR>"] = "actions.select",
        ["<esc><esc>"] = { "actions.close", mode = "n" },
        ["<C-r>"] = "actions.refresh",
        ["<C-p>"] =
        {
          callback = function()
            local oil = require 'oil'
            oil.open_preview { vertical = true, split = 'botright' }
          end,
        },
        ["-"] = { "actions.parent", mode = "n" },
        ["_"] = { "actions.open_cwd", mode = "n" },
        ["gs"] = { "actions.change_sort", mode = "n" },
      },
      use_default_keymaps = false,
    })
  end,
}
