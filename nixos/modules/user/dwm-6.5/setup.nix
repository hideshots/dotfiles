{ config, pkgs, ... }:

{
  home.file.".config/picom.conf".source = ./picom.conf;

  home.packages = with pkgs; [
    hsetroot
    picom
  ];
}
