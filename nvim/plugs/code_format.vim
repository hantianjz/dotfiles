Plug 'stevearc/conform.nvim'

function ConformSetup()
lua << EOF
require("conform").setup({
    formatters_by_ft = {
        python = { "black" },
    }
})

vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    callback = function(args)
        require("conform").format({ bufnr = args.buf })
    end,
})
EOF
endfunction

nmap <leader>f :lua require("conform").format()<CR>

augroup ConformSetup
    autocmd!
    autocmd User PlugLoadedLast call ConformSetup()
augroup END
