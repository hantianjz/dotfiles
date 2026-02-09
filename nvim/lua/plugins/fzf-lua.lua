return {
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>t",  function() require("fzf-lua").files() end,                                                          desc = "Find files" },
      { "<leader>g",  function() require("fzf-lua").git_files() end,                                                      desc = "Git files" },
      { "<leader>b",  function() require("fzf-lua").buffers() end,                                                        desc = "Current buffers" },
      { "<leader>vh", function() require("fzf-lua").help_tags() end,                                                      desc = "Vim help tags" },
      { "<leader>d",  function() require("fzf-lua").diagnostics_document() end,                                           desc = "Buffer diagnostics" },
      { "<leader>D",  function() require("fzf-lua").diagnostics_workspace() end,                                          desc = "Workspace diagnostics" },
      { "<leader>lf", function() require("fzf-lua").lsp_references() end,                                                 desc = "LSP references" },
      { "<leader>ld", function() require("fzf-lua").lsp_definitions() end,                                                desc = "LSP definitions" },
      { "<leader>o",  function() require("fzf-lua").builtin() end,                                                        desc = "fzf-lua builtin" },
      { "<C-q>",      function() require("fzf-lua").quickfix() end,                                                       desc = "Quickfix list" },
      { "<leader>vc", function() require("fzf-lua").files({ cwd = vim.fn.stdpath("config") }) end,                        desc = "Find nvim config" },
      { "<leader>vp", function() require("fzf-lua").files({ cwd = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy") }) end, desc = "Find nvim plugins" },
      { "<leader>s",  function() require("config.fzf.live_multi_grep").live_multigrep() end,                              desc = "Multi-pattern grep" },
    },
    config = function()
      local actions = require("fzf-lua.actions")
      require("fzf-lua").setup({
        "default-title",
        winopts = {
          on_create = function()
            local buf = vim.api.nvim_get_current_buf()
            local win = vim.api.nvim_get_current_win()
            -- Pass <Esc> through to fzf instead of exiting terminal mode
            vim.keymap.set("t", "<Esc>", "<Esc>", { buffer = buf, silent = true, nowait = true })
            -- Hide picker when focus leaves the window (preserves state for resume)
            vim.api.nvim_create_autocmd("WinLeave", {
              buffer = buf,
              callback = function()
                vim.schedule(function()
                  -- If focus moved to another floating window (e.g. preview pane),
                  -- we're still inside fzf-lua's UI — don't hide
                  local new_win = vim.api.nvim_get_current_win()
                  local config = vim.api.nvim_win_get_config(new_win)
                  if config.relative and config.relative ~= "" then
                    return
                  end
                  if vim.api.nvim_win_is_valid(win) then
                    require("fzf-lua").hide()
                  end
                end)
              end,
            })
          end,
          preview = {
            layout = "flex",
            flip_columns = 120,
          },
        },
        keymap = {
          builtin = { ["<Esc>"] = "hide" },
          fzf = { ["ctrl-q"] = "select-all+accept" },
        },
        actions = {
          files = {
            ["default"] = actions.file_edit,
            ["ctrl-q"]  = actions.file_sel_to_qf,
          },
        },
        files = {
          fd_opts = "--type f --strip-cwd-prefix --hidden --follow --exclude .git",
        },
      })
    end
  },
}
