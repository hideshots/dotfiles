{ config, pkgs, inputs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  nix.gc.automatic = true;
  nix.gc.dates = "weekly";
  nix.gc.options = "--delete-older-than 30d";
  nix.settings = {
    substituters = ["https://hyprland.cachix.org"];
    trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
  };

  programs.dconf.enable = true;

  # Networking.
  networking.networkmanager.enable = true;

  # Hyprland.
  programs.hyprland.enable = true;

  # DWM.
  services.xserver.windowManager.dwm = {
    enable = true;
    package = pkgs.dwm.overrideAttrs {
      src = ../modules/system/dwm-6.5;
    };
  };

  # Greeter.
  services.displayManager.ly.enable = true;
  services.displayManager.sessionPackages = [ pkgs.hyprland ]; 

  # Time zone and locales.
  time.timeZone = "Europe/Moscow";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS         = "en_US.UTF-8";
    LC_IDENTIFICATION  = "en_US.UTF-8";
    LC_MEASUREMENT     = "en_US.UTF-8";
    LC_MONETARY        = "en_US.UTF-8";
    LC_NAME            = "en_US.UTF-8";
    LC_NUMERIC         = "en_US.UTF-8";
    LC_PAPER           = "en_US.UTF-8";
    LC_TELEPHONE       = "en_US.UTF-8";
    LC_TIME            = "en_US.UTF-8";
  };

  # X11 settings.
  services.xserver = {
    enable = true;

    xkb = {
      layout = "us,ru";
      variant = ",";
      options = "grp:win_space_toggle";
    };
  };

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.hack
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-mono

    inter
    noto-fonts
  ];

  environment.systemPackages = with pkgs; [
    networkmanagerapplet
    home-manager
    nvchad
    wget
    git
    zsh
    jq
    image-roll
    nautilus

    # wayland
    wl-clipboard
    hyprpaper
    hyprsunset
    waybar
    slurp
    grim

    playerctl
    pavucontrol
    kitty
    tmux

    adwaita-icon-theme
  ];

  # NVChad overlay.
  nixpkgs.overlays = [
    (final: prev: {
      nvchad = inputs.nvchad4nix.packages."${pkgs.system}".nvchad;
    })
  ];

  services.printing.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable             = true;
    alsa.enable        = true;
    alsa.support32Bit  = true;
    wireplumber.enable = true;
    # pulse.enable      = true;
  };

  services.openssh.enable = true;
  system.stateVersion = "24.11";
}
