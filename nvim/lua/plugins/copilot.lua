return {
  {
    "zbirenbaum/copilot.lua",
    enabled = true,
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
