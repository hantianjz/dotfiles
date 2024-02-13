Plug 'hantianjz/conform.nvim'

function ConformSetup()
lua << EOF
require("conform").setup({
    formatters_by_ft = {
        c = { "clang-format" },
        python = { "black" },
        sh = { "shfmt" },
        gn = { "gn" },
        zig = { "zigfmt" },
        rust = { "rustfmt" },
        typescript = { "prettier" },
    }
})

vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    callback = function(args)
        require("conform").format({ bufnr = args.buf, lsp_fallback = true})
    end,
})
EOF
endfunction

nmap <leader>f :lua require("conform").format({lsp_fallback = true})<CR>

augroup ConformSetup
    autocmd!
    autocmd User PlugLoadedLast call ConformSetup()
augroup END
