Plug 'NvChad/nvim-colorizer.lua'

function ColorizerSetup()
lua <<EOF
require 'colorizer'.setup {
  user_default_options = { mode = "foreground", },
}
EOF
endfunction

augroup ColorizerSetup
    autocmd!
    autocmd User PlugLoaded call ColorizerSetup()
augroup END
