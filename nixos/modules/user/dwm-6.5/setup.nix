{ config, pkgs, ... }:

{
  home.file.".config/picom.conf".source = ./picom.conf;

  home.packages = with pkgs; [
    hsetroot
    picom

    # bar
    bc
    alsa-utils
    mpc
    connman
    xorg.xbacklight
    brightnessctl
  ];
}
