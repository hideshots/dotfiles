{
  programs.nixvim = {
    plugins.neo-tree = {
      enable = true;
      window = {
        width = 30;
      };
    };

    keymaps = [{
        key = "<leader>e";
        action = "<cmd>Neotree reveal<cr>";
        options = { desc = "NeoTree reveal"; };
      }
    ];
  };
}
