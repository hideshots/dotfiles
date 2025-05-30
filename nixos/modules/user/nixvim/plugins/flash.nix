{ pkgs, ... }: {
  programs.nixvim = {
    plugins.flash = {
      enable = true;
      autoLoad = true;
    };
      keymaps = [
      {
        key     = "<leader>s";
        action  = "<cmd>lua require('flash').jump()<cr>";
        options = { desc = "Flash jump"; };
      }
    ];
  };
}
