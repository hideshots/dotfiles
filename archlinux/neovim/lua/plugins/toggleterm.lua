return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = "ToggleTerm",
    opts = {
      size = 15,
      open_mapping = [[<M-h>]], -- Alt + h
      hide_numbers = true,
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      insert_mappings = true,
      persist_size = true,
      direction = "horizontal",
      close_on_exit = true,
      shell = vim.o.shell,
      auto_scroll = true,
      float_opts = {
        border = "curved",
        winblend = 0,
        highlights = {
          border = "Normal",
          background = "Normal",
        },
      },
      on_open = function(term)
        vim.cmd("startinsert!")
      end,
      on_close = function(term)
        vim.cmd("startinsert!")
      end,
    },
    keys = {
      -- Primary toggle - Alt + h
      { "<M-h>",      "<cmd>ToggleTerm<cr>",                            desc = "Toggle Terminal",    mode = { "n", "t" } },

      -- Alternative toggles
      { "<leader>tf", "<cmd>ToggleTerm direction=float<cr>",            desc = "Float Terminal" },
      { "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>",       desc = "Horizontal Terminal" },
      { "<leader>tv", "<cmd>ToggleTerm direction=vertical size=80<cr>", desc = "Vertical Terminal" },
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)

      -- Terminal navigation keymaps
      function _G.set_terminal_keymaps()
        local keymap_opts = { buffer = 0 }
        -- Escape to normal mode
        vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], keymap_opts)
        -- Alt + h to toggle terminal from within terminal
        vim.keymap.set('t', '<M-h>', [[<cmd>ToggleTerm<CR>]], keymap_opts)
        -- Window navigation
        vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], keymap_opts)
        vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], keymap_opts)
        vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], keymap_opts)
        vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], keymap_opts)
      end

      -- Apply keymaps to all terminals
      vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
    end,
  }
}
