{ config, pkgs, ... }:

{
  programs.yazi = {
    enable = true;
    package = pkgs.yazi;

    settings = {
      manager = {
        show_hidden = true;
        show_symlink = true;
      };
    };

    flavors = {
      kanagawa = pkgs.fetchFromGitHub {
      owner = "dangooddd";
      repo = "kanagawa.yazi";
      rev = "d98f0c3e27299f86ee080294df2722c5a634495a";
      sha256 = "0hf4553h9r5chqsf6hvk2jb8c4vpbvbdy794phq7vacjs1f75yb7";
      };
    };

    theme = {
      flavor = {
        dark = "kanagawa";
        light = "kanagawa";
      };
    };
  };

  programs.yazi.yaziPlugins = {
    enable = true;
    plugins = {
      relative-motions = {
        enable = true;
        show_numbers = "relative_absolute";
        show_motion = true;
      };
      full-border = {
        enable = true;
      };
      max-preview = {
        enable = true;
        keys.toggle.on = [ "n" ];
      };
    };
  };
}
