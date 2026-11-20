---@mod plugins.treesitter Treesitter configuration
---
--- Configures nvim-treesitter for syntax highlighting and code parsing.
--- Master branch archived 2026 — must use main on nvim 0.12+.

---@type LazySpec[]
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    lazy = false,
    config = function()
      local ts = require('nvim-treesitter')
      -- Neovim caches runtime paths; create the parser install directory before adding it.
      local install_dir = vim.fn.stdpath("data") .. "/site"
      vim.fn.mkdir(install_dir, "p")
      vim.opt.runtimepath:prepend(install_dir)

      local available = ts.get_available()
      local installing = {}
      local get_lang = vim.treesitter.language.get_lang

      local function start(buf, lang)
        if not vim.treesitter.language.add(lang) then
          return false
        end
        if vim.treesitter.query.get(lang, "highlights") then
          vim.treesitter.start(buf, lang)
        end
        if vim.treesitter.query.get(lang, "indents") then
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
        return true
      end

      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          local lang = get_lang(args.match)
          if not lang or installing[lang] or start(args.buf, lang) or not vim.list_contains(available, lang) then
            return
          end

          installing[lang] = true
          ts.install({ lang }):await(vim.schedule_wrap(function(err, installed)
            installing[lang] = nil
            if err then
              vim.notify("Tree-sitter install failed for " .. lang .. ": " .. tostring(err), vim.log.levels.ERROR)
            elseif installed then
              for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_loaded(buf) and get_lang(vim.bo[buf].filetype) == lang then
                  start(buf, lang)
                end
              end
            end
          end))
        end,
      })
    end,
  },
}
