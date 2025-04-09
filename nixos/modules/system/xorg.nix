{ config, pkgs, ... }:

{
  services.xserver = {
    enable = true;
    windowManager.dwm = {
      enable = true;
      package = pkgs.dwm.overrideAttrs (old: rec {
        src = ../user/dwm-6.5;
        buildInputs = (old.buildInputs or []) ++ [ pkgs.imlib2 ];
        CFLAGS = "-O3 -march=native";
      });
    };

    xkb = {
      layout = "us,ru";
      variant = ",";
      options = "grp:win_space_toggle,ctrl:nocaps";
    };
  };

  environment.systemPackages = with pkgs; [
    xorg.xbacklight
    brightnessctl
    redshift
    imlib2
    xclip
    maim

    autotiling
    hsetroot
    picom

    # bar
    alsa-utils
    connman
    mpc
    bc
  ];
}
