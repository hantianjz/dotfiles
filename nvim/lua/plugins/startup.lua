return {
  "goolord/alpha-nvim",
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    local theta = require("alpha.themes.theta")
    local dashboard = require("alpha.themes.dashboard")
    theta.header.val = {}
    theta.buttons.val = {
      { type = "text",    val = "Quick links", opts = { hl = "SpecialComment", position = "center" } },
      { type = "padding", val = 1 },
      dashboard.button("e", "  New file", "<cmd>ene<CR>"),
      dashboard.button("u", "  Update plugins", "<cmd>Lazy sync<CR>"),
      dashboard.button("q", "󰅚  Quit", "<cmd>qa<CR>"),
    }
    require("alpha").setup(
      theta.config
    )
  end,
}
