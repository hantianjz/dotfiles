return {
  "olimorris/codecompanion.nvim",
  enabled = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  keys = {
    {
      "<leader>c",
      function()
        vim.cmd("CodeCompanion")
      end,
      mode = { "n", "v" }
    },
    {
      "<leader><leader>c",
      function()
        vim.cmd("CodeCompanionActions")
      end,
      mode = { "n", "v" }
    },
    {
      "<leader><leader>t",
      function()
        vim.cmd("CodeCompanionChat Toggle")
      end,
      mode = { "n", "v" }
    },
  },
  opts = {
    strategies = {
      chat = {
        adapter = "copilot",
      },
      inline = {
        adapter = "copilot",
      },
    },
    display = {
      chat = {
        show_settings = false,
        start_in_insert_mode = true,
      },
    },
    adapters = {
      copilot = function()
        return require("codecompanion.adapters").extend("copilot", {
          name = "copilot",
          schema = {
            model = {
              default = "claude-3.5-sonnet"
            }
          }
        })
      end,
    },
  },
}
