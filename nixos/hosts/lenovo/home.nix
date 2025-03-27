{ config, pkgs, lib, ... }:

{
  imports = [
    ../home-common.nix
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
  wayland.windowManager.hyprland.settings.input.kb_options = lib.mkForce "grp:win_space_toggle,ctrl:nocaps";
  wayland.windowManager.hyprland.settings.input.force_no_accel = lib.mkForce "0";
  wayland.windowManager.hyprland.settings.input.sensitivity = lib.mkForce "-0.15";

  home.packages = with pkgs; [
    moonlight-qt
    prismlauncher

    brightnessctl
  ];

  home.stateVersion  = "24.11";
}
