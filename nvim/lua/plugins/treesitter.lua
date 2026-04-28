---@mod plugins.treesitter Treesitter configuration
---
--- Configures nvim-treesitter for syntax highlighting and code parsing.
--- Master branch archived 2026 — must use main on nvim 0.12+.

local langs = {
  "bash", "c", "cpp", "lua", "python", "yaml",
  "typescript", "tsx", "javascript", "java",
  "markdown", "markdown_inline", "go", "gomod", "gosum",
}

---@type LazySpec[]
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    lazy = false,
    config = function()
      local ts = require('nvim-treesitter')
      ts.setup({})
      ts.install(langs)

      vim.api.nvim_create_autocmd("FileType", {
        pattern = langs,
        callback = function(args)
          local ok = pcall(vim.treesitter.start, args.buf)
          if ok then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
}
