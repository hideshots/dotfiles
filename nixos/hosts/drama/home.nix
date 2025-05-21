{ config, pkgs, inputs, ... }:

{
  imports = [
    ../home-common.nix
  ];

  programs.git = {
    enable = true;
    userName = "drama";
    userEmail = "drama@nixos.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };
  
  services.easyeffects.enable = true;
  
  # Hyprland configuration overrides.
  wayland.windowManager.hyprland.settings = {
    monitor = lib.mkForce [
      "HDMI-A-2, 1920x1080@144 ,0x0,1"
      "DP-1,     1920x1080@240 ,1920x0,1"
      "HDMI-A-1, 1920x1080@60  ,3840x0,1"
    ];
    workspace = [
      "1, monitor:DP-1"
      "2, monitor:DP-1"
      "3, monitor:DP-1"
      "4, monitor:DP-1"
      "5, monitor:DP-1"
      "6, monitor:DP-1"
      "7, monitor:DP-1"
      "8, monitor:HDMI-A-1"
      "9, monitor:HDMI-A-2"
    ];
  };

  home.packages = with pkgs; [
    obs-studio
    obsidian
    teams-for-linux
    chromium
    easyeffects

    # inputs.nix-gaming.packages.${system}.osu-lazer-bin
    # inputs.nix-gaming.packages.${system}.osu-stable
    prismlauncher
    # rpcs3
  ];

  home = {
    username      = "drama";
    homeDirectory = "/home/drama";
    stateVersion  = "24.11";
  };
}
