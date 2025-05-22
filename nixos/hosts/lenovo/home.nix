{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ../home-common.nix
    ../../modules/user/mangohud.nix
  ];

  programs.git = {
    enable = true;
    userName = "lenovo";
    userEmail = "lenovo@nixos.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  # Hyprland configuration overrides.
  wayland.windowManager.hyprland.settings = {
    monitor = lib.mkForce [
      "eDP-1, preferred, auto, 1, transform, 0"
    ];

    exec-once = [
      "iio-hyprland"     # automatic screen rotation
      "sudo mouseless -c ~/.dotfiles/nixos/modules/user/mouseless/laptop.yaml"
    ];

    bind = [
      "SUPER,O,exec,~/.dotfiles/nixos/modules/user/scripts/my-script.sh"
    ];

    input = {
      force_no_accel = lib.mkForce "0";
      sensitivity = lib.mkForce "-0.15";
    };
  };

  home.packages = with pkgs; [
    # inputs.nix-gaming.packages.${system}.osu-lazer-bin
    moonlight-qt
    prismlauncher
    mouseless

    brightnessctl
  ];
  
  home = {
    username      = "lenovo";
    homeDirectory = "/home/lenovo";
    stateVersion  = "24.11";
  };
}
