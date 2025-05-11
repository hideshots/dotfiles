{ config, pkgs, ... }:

{
  programs.hyprland.enable = true;

  environment.systemPackages = with pkgs; [
    wl-clipboard
    hyprsunset
    libnotify
    hyprpaper
    slurp
    grim
    eww
  ];
}
