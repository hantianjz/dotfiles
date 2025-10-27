return {
  -- Make sure to set this up properly if you have lazy=true
  'MeanderingProgrammer/render-markdown.nvim',
  event = "VeryLazy", -- Or `LspAttach`
  opts = {
    file_types = { "markdown" },
  },
  ft = { "markdown", "Avante", "codecompanion" },
}
