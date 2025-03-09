---@mod plugins.avante AI-powered code assistant configuration
---
--- Configures the avante.nvim plugin for AI-assisted coding with support for
--- multiple AI providers including Copilot and OpenAI.

---@type LazySpec
return {
  "yetone/avante.nvim",
  enabled = false,
  event = "VeryLazy",
  lazy = false,
  version = "*",
  opts = {
    -- AI Provider Configuration
    provider = "copilot",
    auto_suggestions_provider = "openai",
    
    -- OpenAI Configuration
    openai = {
      endpoint = "https://api.openai.com/v1",
      model = "gpt-4o-mini",
      timeout = 30000,
      temperature = 0,
      max_tokens = 4096,
    },

    -- Behavior Settings
    behaviour = {
      auto_suggestions = false, -- Experimental feature
    },

    -- RAG Service Configuration
    rag_service = {
      enabled = false, -- Requires OPENAI_API_KEY
    },

    -- UI Configuration
    windows = {
      position = "left",
      width = 40,
    },

    -- Keymaps
    mappings = {
      ask = "<leader>aa",     -- Ask AI assistant
      edit = "<leader>ae",    -- Edit suggestion
      refresh = "<leader>ar", -- Refresh suggestions
      suggestion = {
        accept = "<S-Tab>",
        next = "<S-Down>",
        prev = "<S-Up>",
      },
    }
  },

  -- Build Configuration
  build = "make", -- Use "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" for Windows

  -- Dependencies
  dependencies = {
    -- Core dependencies
    'Kaiser-Yang/blink-cmp-avante',
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    
    -- Optional dependencies for file selection
    "echasnovski/mini.pick", -- File selector provider: mini.pick
    "ibhagwan/fzf-lua",      -- File selector provider: fzf
    "giuxtaposition/blink-cmp-copilot",
  },
}