return {
  { 'nvim-tree/nvim-web-devicons', opt = { default = true } },
  { 'svermeulen/vim-easyclip' },
  { 'tpope/vim-endwise' },
  { 'tpope/vim-repeat' },
  -- Language plugins
  {
    'ziglang/zig.vim',
    ft = "zig"
  },
  { 'rust-lang/rust.vim', ft = "rust" },
  {
    'https://gn.googlesource.com/gn',
    config = function(plugin)
      vim.opt.rtp:append(plugin.dir .. '/misc/vim')
    end,
    ft = "gn"
  }
}
