return {
  { "JoosepAlviste/nvim-ts-context-commentstring" },
  {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup {
        pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
        mappings = { basic = true, extra = false }
      }
    end,
  },
}
