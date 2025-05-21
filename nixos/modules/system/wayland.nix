{ config, pkgs, inputs, ... }:

{
  programs.hyprland.enable = true;

  environment.systemPackages = with pkgs; [
    nwg-dock-hyprland
    wl-clipboard
    hyprsunset
    libnotify
    hyprpaper
    slurp
    grim
    eww
  ];
}
