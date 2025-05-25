{ pkgs, ... }:

{
  programs.nixvim = {
    enable = true;

    plugins.toggleterm = {
      enable   = true;
      package  = pkgs.vimPlugins.toggleterm-nvim;
      autoLoad = true;

      settings = {
        open_mapping    = "";
        direction       = "horizontal";
        size            = 8;
        close_on_exit   = true;
      };
    };

    extraConfigLua = ''
      local Terminal = require("toggleterm.terminal").Terminal

      local float_term = Terminal:new{
        direction     = "float",
        close_on_exit = true,
        on_open = function(term)
          vim.api.nvim_buf_set_keymap(
            term.bufnr,
            "t",
            "<Esc>",
            "<cmd>close<CR>",
            { silent = true, desc = "Float term: close on ESC" }
          )
        end,
      }

      vim.keymap.set(
        "n",
        "<A-i>",
        function() float_term:toggle() end,
        { desc = "Alt+i: Toggle floating terminal" }
      )

      vim.keymap.set(
        { "n", "t" },
        "<A-h>",
        "<cmd>ToggleTerm size=17 direction=horizontal<cr>",
        { desc = "Alt+h: Toggle horizontal terminal" }
      )
    '';
  };
}

