return {
  "yetone/avante.nvim",
  enabled = false,
  event = "VeryLazy",
  lazy = false,
  version = "*",
  opts = {
    provider = "copilot",
    auto_suggestions_provider = "openai",
    openai = {
      endpoint = "https://api.openai.com/v1",
      model = "gpt-4o-mini",
      timeout = 30000, -- timeout in milliseconds
      temperature = 0, -- adjust if needed
      max_tokens = 4096,
      -- reasoning_effort = "high" -- only supported for reasoning models (o1, etc.)
    },
    behaviour = {
      auto_suggestions = false, -- Experimental stage
    },
    rag_service = {
      enabled = false, -- Enables the rag service, requires OPENAI_API_KEY to be set
    },
    windows = {
      position = "left",
      width = 40,
    },
    mappings = {
      ask = "<leader>aa",     -- ask
      edit = "<leader>ae",    -- edit
      refresh = "<leader>ar", -- refresh
      suggestion = {
        accept = "<S-Tab>",
        next = "<S-Down>",
        prev = "<S-Up>",
      },
    }
  },
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  build = "make",
  -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
  dependencies = {
    'Kaiser-Yang/blink-cmp-avante',
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    --- The below dependencies are optional,
    "echasnovski/mini.pick", -- for file_selector provider mini.pick
    "ibhagwan/fzf-lua",      -- for file_selector provider fzf
    "giuxtaposition/blink-cmp-copilot",
  },
}
