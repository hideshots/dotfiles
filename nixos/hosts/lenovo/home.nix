{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ../home-common.nix
    ../../modules/user/mangohud.nix
  ];

  home.username      = "lenovo";
  home.homeDirectory = "/home/lenovo";

  programs.git = {
    enable = true;
    userName = "lenovo";
    userEmail = "lenovo@nixos.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  # Hyprland config override
  wayland.windowManager.hyprland.settings = {
    monitor = lib.mkForce [
      "eDP-1,preferred,auto,1,transform,0"
    ];

    exec-once = [
      "iio-hyprland" # auto-rotation
    ];

    bind = [
      "SUPER,O,exec,~/.dotfiles/nixos/modules/user/scripts/"
    ];
  };

  wayland.windowManager.hyprland.settings.input.force_no_accel = lib.mkForce "0";
  wayland.windowManager.hyprland.settings.input.sensitivity = lib.mkForce "-0.15";

  home.packages = with pkgs; [
    # inputs.nix-gaming.packages.${system}.osu-lazer-bin
    moonlight-qt
    prismlauncher

    brightnessctl
  ];

  home.stateVersion  = "24.11";
}
