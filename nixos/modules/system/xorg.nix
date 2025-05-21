{ config, pkgs, ... }:

let
  # 1) Grab the Stylix wallpaper path
  wallpaper = config.stylix.image;
in
{
  services.xserver = {
    enable = true;
    windowManager.dwm = {
      enable = true;
      package = pkgs.dwm.overrideAttrs (old: rec {
# point at *your* source first
          src = ../user/dwm-6.5;

# add any extra build inputs
          buildInputs = (old.buildInputs or []) ++ [ pkgs.imlib2 ];

# now patch in the right working directory (no need for ${old.src})
          preConfigure = ''
          substituteInPlace config.h \
          --replace \
          "hsetroot -cover ~/.dotfiles/wallpapers/aletiune_2.png" \
          "hsetroot -cover ${wallpaper}"
          '';

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
