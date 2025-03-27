return {
  "joshuavial/aider.nvim",
  keys = {
    {
      "<leader>c",
      function()
        vim.cmd("AiderOpen")
      end,
      mode = { "n" }
    },
  },
  opts = {
    -- your configuration comes here
    -- if you don't want to use the default settings
    auto_manage_context = true, -- automatically manage buffer context
    default_bindings = false,   -- use default <leader>A keybindings
    debug = false,              -- enable debug logging
  },
}
