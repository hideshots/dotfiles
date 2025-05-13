{ inputs, pkgs, ... }:

{
  stylix = {
    enable = true;
    autoEnable = false;
    image = ../../../wallpapers/cherry_3.png;
    polarity = "dark";

    homeManagerIntegration = {
      autoImport = true;
      followSystem = true;
    };

    override = {
      # Black-Metal 
      base00 = "#000000";
      base01 = "#121212";
      base02 = "#222222";
      base03 = "#333333";
      base04 = "#999999";
      base05 = "#c1c1c1";
      base06 = "#999999";
      base07 = "#c1c1c1";
      # base0A
      # base0B
      base0C = "#aaaaaa";
      base0D = "#888888";
      base0E = "#999999";
      base0F = "#444444";
    };

    targets = {
      grub     = { enable = true; };
      console  = { enable = true; };
    };

    fonts = {
      serif = {
        package = inputs.apple-fonts.packages.${pkgs.system}.sf-pro;
        name = "SF Pro";
      };

      sansSerif = {
        package = inputs.apple-fonts.packages.${pkgs.system}.sf-pro;
        name = "SF Pro";
      };

      monospace = {
        package = inputs.apple-fonts.packages.${pkgs.system}.sf-mono-nerd;
        name = "SF Mono Nerd Font";
      };

      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
    };

    cursor = {
      package = pkgs.whitesur-cursors;
      name = "WhiteSur-cursors";
      size = 16;
    };
  };
}
