return {
  { 'nvim-tree/nvim-web-devicons', opt = { default = true } },
  { 'echasnovski/mini.nvim',       version = '*' },
  { 'svermeulen/vim-easyclip' },
  { 'airblade/vim-gitgutter' },
  { 'tpope/vim-bundler' },
  { 'tpope/vim-commentary' },
  { 'tpope/vim-sensible' },
  { 'tpope/vim-endwise' },
  { 'tpope/vim-repeat' },
  { 'tpope/vim-vinegar' },
  { 'tpope/vim-speeddating' },
  -- Language plugins
  { 'ziglang/zig.vim' },
  { 'rust-lang/rust.vim' },
  {
    'https://gn.googlesource.com/gn',
    config = function(plugin)
      vim.opt.rtp:append(plugin.dir .. '/misc/vim')
    end
  }
}
