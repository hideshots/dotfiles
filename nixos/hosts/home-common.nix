{ config, pkgs, inputs, system, ... }:

{
  imports = [
    ../modules/user/hyprland/setup.nix
    ../modules/user/shell.nix
    ../modules/user/spicetify.nix
    ../modules/user/tmux.nix
    ../modules/user/yazi.nix
    ../modules/user/rofi.nix
    inputs.nix-yazi-plugins.legacyPackages.x86_64-linux.homeManagerModules.default
    inputs.spicetify-nix.homeManagerModules.default
  ];

  stylix.targets.rofi.enable = false;
  stylix.targets.hyprland.enable = false;
  stylix.targets.spicetify.enable = false;

  services.easyeffects.enable = true;

  home.packages = with pkgs; [
    # Audio
    easyeffects

    # General apps
    inputs.zen-browser.packages."${system}".beta
    haskellPackages.greenclip
    telegram-desktop
    btop
    mpv

    # Development
    (python3.withPackages (ps: with ps; [ requests ]))
  ];

  xdg.configFile."gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-icon-theme-name=Adwaita
  '';

  xdg.configFile."gtk-4.0/settings.ini".text = ''
    [Settings]
    gtk-icon-theme-name=Adwaita
  '';

  home.sessionVariables = {
    EDITOR = "nvim";
  };
}
