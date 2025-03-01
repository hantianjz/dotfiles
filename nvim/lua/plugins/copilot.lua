return {
  {
    enabled = false,
    "zbirenbaum/copilot.lua",
    dependencies =
    {
      "giuxtaposition/blink-cmp-copilot",
    },
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = { enabled = false },
        panel = { enabled = false },
      })
    end,
  },
}
