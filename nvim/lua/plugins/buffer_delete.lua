return {
  "famiu/bufdelete.nvim",

  keys = {
    {
      "<leader>q",
      function()
        require("bufdelete").bufwipeout(0)
      end,
      mode = { "n", "v" },
      desc = "Wipe out current buffer",
    },
  },
}
