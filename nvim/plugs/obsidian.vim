Plug 'epwalsh/obsidian.nvim'

function ObsidianSetup()
lua << EOF
if vim.fn.isdirectory(".obsidian")==1 then
  vim.opt.conceallevel = 1
  require("obsidian").setup(
  {
      detect_cwd = false,
      daily_notes = {
        folder = "6 Database",
        template = "_templates/daily.md"
        }
  }
  )
end
EOF
endfunction

augroup ObsidianSetup
    autocmd!
    autocmd User PlugLoadedLast call ObsidianSetup()
augroup END
