return {
  { 'nvim-tree/nvim-web-devicons', opt = { default = true } },
  { 'svermeulen/vim-easyclip' },
  { 'airblade/vim-gitgutter' },
  { 'tpope/vim-bundler' },
  { 'tpope/vim-commentary' },
  { 'tpope/vim-endwise' },
  { 'tpope/vim-repeat' },
  { 'tpope/vim-surround' },
  { 'tpope/vim-vinegar' },
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
