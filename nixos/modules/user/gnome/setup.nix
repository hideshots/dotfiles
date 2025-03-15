{ config, pkgs, ... }:

{
  # imports =
  #   [
  #     ./dconf.nix
  #   ];

  dconf.enable = true;

  home.packages = with pkgs; [
    gnomeExtensions.blur-my-shell
    gnome-tweaks
  ];
}
