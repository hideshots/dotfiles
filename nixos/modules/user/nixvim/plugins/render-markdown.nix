{ pkgs, ... }:

{
  programs.nixvim = {
    plugins.render-markdown = {
      enable   = true;
      autoLoad = true;

      settings = {
        enable = true;                    # globally enable rendering
        autoLoad = true;                  # automatically render on startup
        file_types = [ "markdown" ];      # which filetypes to render

        paragraph = {
          firstIndent = 2;
        };

        table = {
          border = "single";              # options: "single", "double", "rounded", etc.
        };
      };
    };
  };
}
