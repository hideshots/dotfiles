{
  programs.nixvim = {
    plugins.treesitter = {
      enable = true;

      settings = {
        # ensureInstalled = [
        #   "vimdoc"
        # ];

        highlight = {
          enable = true;

          # Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
          additional_vim_regex_highlighting = true;
        };

        indent = {
          enable = true;
          disable = [
            "ruby"
          ];
        };
      };
    };
  };
}
