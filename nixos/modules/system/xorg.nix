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
    autotiling
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
