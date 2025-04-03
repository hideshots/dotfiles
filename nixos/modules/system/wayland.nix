{ config, pkgs, ... }:

{
  programs.hyprland.enable = true;

  environment.systemPackages = with pkgs; [
    wl-clipboard
    hyprsunset
    hyprpaper
    waybar
    slurp
    grim
    eww
  ];
}
