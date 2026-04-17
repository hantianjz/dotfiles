local function cwd_already_served()
  local dir = (vim.env.CLAUDE_CONFIG_DIR or vim.fn.expand("~/.claude")) .. "/ide"
  if vim.fn.isdirectory(dir) == 0 then return false end
  local cwd = vim.uv.cwd()
  for _, f in ipairs(vim.fn.glob(dir .. "/*.lock", false, true)) do
    local raw = table.concat(vim.fn.readfile(f), "\n")
    local ok, data = pcall(vim.fn.json_decode, raw)
    if ok and type(data) == "table" and data.pid and data.workspaceFolders then
      for _, wf in ipairs(data.workspaceFolders) do
        if wf == cwd and data.pid ~= vim.fn.getpid() then
          local alive = vim.uv.kill(data.pid, 0) == 0
          if alive then return true end
        end
      end
    end
  end
  return false
end

return {
  "coder/claudecode.nvim",
  cond = function()
    if not vim.env.TMUX then return false end
    if cwd_already_served() then return false end
    return true
  end,
  lazy = false,
  opts = {
    auto_start = true,
    terminal = { provider = "none" },
    log_level = "info",
  },
  config = function(_, opts)
    local lf = require("claudecode.lockfile")
    local orig = lf.create
    lf.create = function(...)
      local res = { orig(...) }
      local path = res[1]
      if type(path) == "string" and vim.fn.filereadable(path) == 1 then
        local raw = table.concat(vim.fn.readfile(path), "\n")
        local ok, data = pcall(vim.fn.json_decode, raw)
        if ok and type(data) == "table" then
          local sess = vim.fn.system("tmux display-message -p '#S' 2>/dev/null"):gsub("%s+$", "")
          if sess == "" then sess = "?" end
          data.ideName = ("Neovim [%s:%d]"):format(sess, vim.fn.getpid())
          vim.fn.writefile({ vim.fn.json_encode(data) }, path)
        end
      end
      return unpack(res)
    end
    require("claudecode").setup(opts)
  end,
  keys = {},
}
