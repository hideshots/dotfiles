{ pkgs, ... }:
{
  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    plugins.ccc = {
      enable   = true;
      autoLoad = true;
      settings = {
        highlighter = {
          auto_enable = true;
          highlight_mode = "virtual";
          lsp = true;
        };
      };
    };

    keymaps = [
      {
        mode = "n";
        key  = "<leader>cp";
        action = "<cmd>CccPick<CR>";
        options = {
          desc = "Open CCC color picker";
        };
      }
    ];
  };
}
