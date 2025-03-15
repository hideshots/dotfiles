{ inputs, pkgs, ... }:

{
  stylix.enable = true;
  stylix.autoEnable = true;
  stylix.image = ../../wallpapers/cherry_3.png;
  stylix.polarity = "dark";

  # Home Manager integration options
  stylix.homeManagerIntegration = {
    autoImport = true;  # Automatically import Stylix into every Home Manager user
    followSystem = true;  # Make Home Manager follow the NixOS configuration by default
  };

  stylix.fonts = {
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

  stylix.cursor = {
    package = pkgs.whitesur-cursors;
    name = "WhiteSur-cursors";
    size = 16;
  };
}
