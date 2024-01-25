Plug 'nvim-lualine/lualine.nvim'

function LuaLineSetup()
lua << END

local filepath = vim.fn.expand('%:p:h')

require('lualine').setup {
  options = {
    theme = 'auto'
  },
  sections = {
    lualine_c = {
      { 'filename', path = 1, newfile_status = true }
    },
    lualine_b = { 'diff', 'diagnostics' },
    lualine_x = { 'encoding', 'fileformat', 'filetype', "filesize" },
  },
  inactive_sections = {
    lualine_c = {
      { 'filename', path = 1 }
    },
  },
}
END
endfunction

augroup LuaLineSetup
    autocmd!
    autocmd User PlugLoaded call LuaLineSetup()
augroup END
