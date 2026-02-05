local M = {}

function M.live_multigrep(opts)
  opts = opts or {}
  local fzf_lua = require("fzf-lua")

  fzf_lua.fzf_live(function(args)
    local query = type(args) == "table" and args[1] or args
    if type(query) ~= "string" or query == "" then
      return "true"
    end

    local patterns = vim.split(query, " ", { trimempty = true })
    local search_pattern = "^"
    for _, str in ipairs(patterns) do
      search_pattern = search_pattern .. "(?=.*" .. str .. ")"
    end
    search_pattern = search_pattern .. ".*$"

    return string.format(
      "rg --color=always --no-heading --with-filename --line-number --column --smart-case -P %s",
      vim.fn.shellescape(search_pattern)
    )
  end, {
    cwd = opts.cwd or vim.uv.cwd(),
    prompt = "Multi Grep> ",
    exec_empty_query = false,
    previewer = "builtin",
    fn_transform = function(x)
      return fzf_lua.make_entry.file(x, { file_icons = true, color_icons = true })
    end,
    actions = {
      ["default"] = require("fzf-lua.actions").file_edit,
      ["ctrl-q"]  = require("fzf-lua.actions").file_sel_to_qf,
    },
  })
end

return M
