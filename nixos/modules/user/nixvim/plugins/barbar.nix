{ config, pkgs, lib, ... }:

{
  programs.nixvim = {
    plugins.barbar = {
      enable   = true;
      autoLoad = true;
      settings = {
        autohide = 3;
        sidebar_filetypes = {
          "neo-tree" = true;
        };

        icons = {
          separator = {
            left  = "";
            right = "";
          };

          current = {
            separator = {
              left  = "";
              right = "";
            };
          };

          inactive = {
            separator = {
              left  = "";
              right = "";
            };
          };

          buffer_index = false;
          buffer_number = false;
          button = false;
        };
      };
    };

    keymaps = [
      # Cycle to the next buffer/tab
      {
        mode   = "n";
        key    = "<Tab>";
        action = "<Cmd>BufferNext<CR>";
        options = { desc = "Next Buffer"; };
      }

      # Cycle to the previous buffer/tab
      {
        mode   = "n";
        key    = "<S-Tab>";
        action = "<Cmd>BufferPrevious<CR>";
        options = { desc = "Previous Buffer"; };
      }

      # Close buffer
      {
        mode   = "n";
        key    = "<leader>x";
        action = "<Cmd>BufferClose<CR>";
        options = { desc = "Close Buffer"; };
      }
    ];
  };
}
