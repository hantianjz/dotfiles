---@mod live_multi_grep Live multi-pattern grep extension for Telescope
---
--- This module provides a live grep functionality that allows searching with both
--- a pattern for content and a pattern for file paths. The patterns are separated
--- by two spaces.
---
--- Usage: Type your search pattern, then two spaces, then an optional file pattern
--- Example: "function  *.lua" will search for "function" in all Lua files

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local make_entry = require "telescope.make_entry"
local conf = require("telescope.config").values

local M = {}

---@class LiveMultiGrepOpts
---@field cwd? string Working directory for the search
---@field debounce? number Debounce time in milliseconds
---@field additional_args? table Additional arguments for ripgrep

---Execute a live multi-pattern grep search
---@param opts? LiveMultiGrepOpts Configuration options
local live_multigrep = function(opts)
  opts = opts or {}
  opts.cwd = opts.cwd or vim.uv.cwd()
  local debounce_time = opts.debounce or 100

  local finder = finders.new_async_job {
    command_generator = function(prompt)
      if not prompt or prompt == "" then
        return nil
      end

      -- Split on double space to separate search pattern and file pattern
      local patterns = vim.split(prompt, " ; ")
      local search_pattern = patterns[1]
      local file_pattern = patterns[2]

      -- Base ripgrep command with standard options
      local args = {
        "rg",
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
        "--smart-case",
      }

      -- Add search pattern if provided
      if search_pattern and search_pattern ~= "" then
        vim.list_extend(args, { "-e", search_pattern })
      end

      -- Add file pattern if provided
      if file_pattern and file_pattern ~= "" then
        vim.list_extend(args, { "-g", file_pattern })
      end

      -- Add any additional user-specified arguments
      if opts.additional_args then
        vim.list_extend(args, opts.additional_args)
      end

      return args
    end,
    entry_maker = make_entry.gen_from_vimgrep(opts),
    cwd = opts.cwd,
  }

  pickers.new(opts, {
    debounce = debounce_time,
    prompt_title = "Multi Grep",
    finder = finder,
    previewer = conf.grep_previewer(opts),
    sorter = require("telescope.sorters").empty(),
  }):find()
end

---Setup the live multi-grep extension
---@param opts? table Optional configuration table
function M.setup(opts)
  -- Set up the keybinding
  vim.keymap.set("n", "<leader>s", function()
    live_multigrep(opts)
  end, {
    desc = "Live multi-pattern grep search",
  })
end

return M
