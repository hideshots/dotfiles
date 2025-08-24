-- lua/plugins/which-key.lua
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  opts = {
    preset = "helix",
    
    win = {
      border = "none",
      padding = { 0, 0, 0, 0 },
      wo = {
        winblend = 60,
      },
      title = false,
    },
    
    layout = {
      width = { min = 0, max = 50 },
      height = { min = 0, max = 25 },
    },
    
    keys = {
      scroll_down = "<Down>",
      scroll_up = "<Up>",
    },

    icons = {
      separator = "::",
    },
    
    show_help = false,
    show_keys = false,
  },
  
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Local Keymaps (which-key)",
    },
    {
      "<leader>k",
      function()
        require("which-key").show({ keys = "<leader>", loop = true })
      end,
      desc = "Keymaps",
    },
  },
}
