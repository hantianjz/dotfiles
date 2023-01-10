Plug 'nvim-lualine/lualine.nvim'

function LuaLineSetup()
lua << END
require('lualine').setup {
  options = {
    theme = 'auto'
  }
}
END
endfunction

augroup LuaLineSetup
    autocmd!
    autocmd User PlugLoaded call LuaLineSetup()
augroup END
