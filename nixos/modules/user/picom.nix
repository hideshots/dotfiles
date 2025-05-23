{ config, pkgs, ... }:

{
  xdg.configFile."picom.conf".text = ''
    # Shadows
    shadow = false;
    shadow-radius = 64;
    shadow-offset-x = -64;
    shadow-offset-y = 0;
    shadow-opacity = 0.65;

    # Fading
    fading = true;
    fade-in-step = 0.03;
    fade-out-step = 0.03;

    # Transparency / Opacity
    frame-opacity = 0;

    # Corners
    corner-radius = 6;

    # Blur
    blur-method = "dual_kawase";
    blur-strength = 7;
    blur-background = true;
    blur-kern = "3x3box";

    # General Settings
    backend = "glx";
    dithered-present = false;
    vsync = true;
    detect-rounded-corners = true;
    detect-client-opacity = true;
    use-damage = true;
    detect-transient = true;
    unredir-if-possible = true;

    # Window Rules
    rules: (
      {
        match = "window_type = 'tooltip'";
        fade = false;
        shadow = true;
        opacity = 0.75;
        full-shadow = false;
      },
      {
        match = "window_type = 'dock'    || window_type = 'desktop' || _GTK_FRAME_EXTENTS@";
        blur-background = false;
      },
      {
        match = "focused";
        opacity = 1.0;
      },
      {
        match = "!focused";
        opacity = 0.8;
      },
      {
        match = "name *= 'scrot' || name *= 'maim'";
        blur-background = false;
        opacity = 1.0;
      },
      {
        match = "window_type != 'dock'";
      },
      {
        match = "window_type = 'dock' || window_type = 'desktop'";
        corner-radius = 0;
      },
      {
        match = "name = 'Notification'   || class_g = 'Conky'       || class_g ?= 'Notify-osd' || class_g = 'Cairo-clock' || _GTK_FRAME_EXTENTS@";
        shadow = false;
      }
    );

    # Animations
    animations = (
      {
        triggers = [ "open" ];
        preset = "appear";
        duration = 0.2;
        scale = 1.0;
      },
      {
        triggers = [ "close", "hide" ];
        preset = "disappear";
        duration = 0.2;
        scale = 1.0;
      },
      {
        triggers = [ "geometry" ];
        preset = "geometry-change";
        duration = 0.3;
      }
    );
  '';
}
