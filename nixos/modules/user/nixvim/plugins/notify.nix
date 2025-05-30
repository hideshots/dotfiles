{ pkgs, ... }: {
  programs.nixvim = {
    plugins.notify = {
      enable = true;
      autoLoad = true;

      settings = {
        max_height     = 10;
        max_width      = 60;
        minimum_width  = 50;

        render = "wrapped-compact";
        stages = "fade_in_slide_out";
        background_colour = "#000000";
        timeout = 3000;
        top_down = true;
        fps = 60;

        icons = {
          debug = "";
          error = "";
          info  = "";
          trace = "✎";
          warn  = "";
        };

        level = "info";
      };
    };
  };
}
