{ config, pkgs, inputs, ... }:

{
  programs.hyprland.enable = true;

  environment.systemPackages = with pkgs; [
    inputs.pyprland.packages.${system}.default
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
