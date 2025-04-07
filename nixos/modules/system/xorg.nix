{ config, pkgs, ... }:

{
  services.xserver = {
    enable = true;
    windowManager.dwm = {
      enable = true;
      package = pkgs.dwm.overrideAttrs {
        src = ../user/dwm-6.5;
      };
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
