return {
  "rachartier/tiny-inline-diagnostic.nvim",
  event = "VeryLazy", -- Or `LspAttach`
  priority = 1000,    -- needs to be loaded in first
  config = function()
    require("tiny-inline-diagnostic").setup({
      preset = "ghost",

      options = {
        show_source = true,
        set_arrow_to_diag_color = true,
        add_messages = true,
        multilines = {
          enabled = true,
          always_show = true,
        },
      }
    })
  end
}
