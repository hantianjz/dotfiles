---@mod plugins.startup Startup screen configuration
---
--- Configures alpha-nvim for a custom startup screen with quick actions
--- and a minimal interface.

---@type LazySpec
return {
  "goolord/alpha-nvim",
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    local theta = require("alpha.themes.theta")
    local dashboard = require("alpha.themes.dashboard")

    -- Clear the default header
    theta.header.val = {}

    -- Configure quick action buttons
    theta.buttons.val = {
      -- Section header
      {
        type = "text",
        val = "Quick links",
        opts = {
          hl = "SpecialComment",
          position = "center"
        }
      },

      -- Spacing
      { type = "padding", val = 1 },

      -- Action buttons
      dashboard.button("e", "  New file", "<cmd>ene<CR>"),
      dashboard.button("u", "  Update plugins", "<cmd>Lazy sync<CR>"),
      dashboard.button("q", "󰅚  Quit", "<cmd>qa<CR>"),
    }

    -- Apply the configuration
    require("alpha").setup(theta.config)
  end,
}

