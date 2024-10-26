return {
  {
    'nvim-lualine/lualine.nvim',
    opts = {
      options = {
        theme = 'catppuccin'
      },
      sections = {
        lualine_c = {
          { 'filename', path = 1, newfile_status = true }
        },
        lualine_b = { 'diff', 'diagnostics', { 'b:gitsigns_head', icon = '' }, },
        lualine_x = { 'encoding', 'fileformat', 'filetype', "filesize" },
      },
      inactive_sections = {
        lualine_c = {
          { 'filename', path = 1 }
        },
      },
    }
  }
}
