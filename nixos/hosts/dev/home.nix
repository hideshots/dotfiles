{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    ../home-common.nix
    ../../modules/user/gimp.nix
    ../../modules/user/nixvim/nixvim.nix
  ];

  programs.git = {
    enable = true;
    userName = "vm";
    userEmail = "dev@vmware.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  # Hyprland configuration overrides.
  wayland.windowManager.hyprland.settings = {
    monitor = lib.mkForce [
      "Virtual-3, 1920x1080@60, 0x0,1"
      "Virtual-1, 1920x1080@60, 1920x0,1"
      "Virtual-2, 1920x1080@60, 3840x0,1"
    ];
    workspace = [
      "1, monitor:Virtual-1"
      "2, monitor:Virtual-1"
      "3, monitor:Virtual-1"
      "4, monitor:Virtual-1"
      "5, monitor:Virtual-1"
      "6, monitor:Virtual-1"
      "7, monitor:Virtual-1"
      "8, monitor:Virtual-3"
      "9, monitor:Virtual-2"
    ];
  };

  home = {
    username      = "dev";
    homeDirectory = "/home/dev";
    stateVersion  = "24.11";
  };
}
