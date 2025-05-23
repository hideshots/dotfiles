{ pkgs, inputs, ... }: {
  programs.nixvim.plugins.comment = {
    enable   = true;
    autoLoad = true;
  };

  programs.nixvim.extraConfigLuaPre = ''
    -- Initialize Comment.nvim with default settings
    require('Comment').setup {}
  '';

  programs.nixvim.keymaps = [
    {
      mode = "n";
      key  = "<leader>/";
      action = "<cmd>lua require('Comment.api').toggle.linewise.current()<CR>";
      options = { desc = "Toggle comment on current line"; };
    }
    {
      mode = "v";
      key  = "<leader>/";
      action = "<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>";
      options = { desc = "Toggle comment on selection"; };
    }
  ];
}
