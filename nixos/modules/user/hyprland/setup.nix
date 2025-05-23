{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    # ./hypridle.nix
    # ./hyprlock.nix
    ../swaync/setup.nix
    ../waybar/setup.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.variables = ["--all"];

    settings = {
      monitor = [
        ", preferred, auto, 1"
      ];

      "$terminal" = "kitty";
      "$fileManager" = "nautilus";
      "$menu" = "rofi -show drun";

      exec-once = [
        "hyprctl reload"
        "dbus-launch --exit-with-session"
        "nm-applet &"
        "hyprsunset &"
        "hyprpaper & waybar & swaync &"
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"

        # "discordcanary &"
        "telegram-desktop -startintray &"
        # "AmneziaVPN &"
        # "steam &"
        # "spotify &"
      ];

      env = [
        "MOZ_ENABLE_WAYLAND,1"
        "XDG_SESSION_TYPE,wayland"
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
        "NIXOS_OZONE_WL=1"
      ];

      general = {
        gaps_in = 6;
        gaps_out = 10;
        border_size = 0;
        resize_on_border = false;
        allow_tearing = true;
        layout = "dwindle";
      };

      decoration = {
        rounding = 5;
        # dim_inactive = true;
        # dim_strength = 0.2;
        # active_opacity = 1.0;
        # inactive_opacity = 0.85;

        shadow = {
          enabled = true;
          range = 50;
          render_power = 3;
          offset = "0 9";
          scale = 0.98;
          color = lib.mkForce "rgba(00000088)";
        };

        blur = {
          enabled = true;
          size = 12;
          passes = 4;
          vibrancy = 1;
          vibrancy_darkness = 0.1;
          # brightness = 1.0;
          noise = 0.015;
        };
      };

      animations = {
        enabled = "yes, please :)";

        bezier = [
          "easeOutQuint,0.23,1,0.32,1"
          "easeInOutCubic,0.65,0.05,0.36,1"
          "linear,0,0,1,1"
          "almostLinear,0.5,0.5,0.75,1.0"
          "quick,0.15,0,0.1,1"
          "easeOutQuart, 0.075, 0.82, 0.165, 1"
          "custom, 0.06, 0.68, 0.27, 0.96"
        ];

        animation = [
          "global, 1, 10, default"
          "border, 1, 5.39, easeOutQuint"
          "windows, 1, 4.79, easeOutQuint"
          "windowsIn, 1, 4.1, easeOutQuint,"
          "windowsOut, 1, 1.49, linear, popin"
          "windowsMove, 1, 3.49, custom, slide"
          "fadeIn, 1, 1.73, almostLinear"
          "fadeOut, 1, 1.46, almostLinear"
          "fade, 1, 3.03, quick"
          "layers, 1, 3.81, easeOutQuint"
          "layersIn, 1, 4, easeOutQuint, fade"
          "layersOut, 1, 1.5, linear, fade"
          "fadeLayersIn, 1, 1.79, almostLinear"
          "fadeLayersOut, 1, 1.39, almostLinear"
          "workspaces, 1, 3.5, easeOutQuart, slide"
          "workspacesIn, 1, 3.5, easeOutQuart, slide"
          "workspacesOut, 1, 3.5, easeOutQuart, slide"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      master = {
        new_status = "master";
      };

      input = {
        kb_layout = "us,ru";
        kb_variant = "";
        kb_model = "";
        kb_options = "grp:win_space_toggle,ctrl:nocaps";
        kb_rules = "";
        follow_mouse = 0;
        accel_profile = "flat";
        force_no_accel = 1;
        sensitivity = 0.000000;
        touchpad = {
          disable_while_typing = false;
          scroll_factor = 1.0;
          tap_button_map = "lrm";
          clickfinger_behavior = false;
          tap-to-click = true;
          drag_lock = false;
          tap-and-drag = true;
          flip_x = false;
          flip_y = false;
        };
      };

      gestures = {
        workspace_swipe = true;
      };

      "$mainMod" = "WIN";

      bind = [
        "WIN, F6, exec, ~/.dotfiles/nixos/modules/user/scripts/toggle-touchpad.sh"
        "$mainMod, Q, exec, $terminal"
        "$mainMod SHIFT, Q, killactive,"
        "$mainMod SHIFT, E, exit,"
        "$mainMod, E, exec, $fileManager"
        "$mainMod, C, togglefloating,"
        "$mainMod, R, exec, $menu"
        "$mainMod, M, exec, rofi -show drun -theme launchpad-dark"
        "$mainMod, F, fullscreen,"

        "$mainMod SHIFT, W, exec, pkill waybar && waybar -c ~/.dotfiles/nixos/modules/user/waybar/config.jsonc -s ~/.dotfiles/nixos/modules/user/waybar/style.css"
        "$mainMod SHIFT, N, exec, pkill swaync && swaync -c .dotfiles/nixos/modules/user/swaync/config.json -s .dotfiles/nixos/modules/user/swaync/style.css "
        "$mainMod, N, exec, swaync-client -t" 
        "$mainMod, B, exec, ~/.dotfiles/nixos/modules/user/hyprland/gamemode.sh" 

        "$mainMod, h, movefocus, l"
        "$mainMod, l, movefocus, r"
        "$mainMod, k, movefocus, u"
        "$mainMod, j, movefocus, d"

        "$mainMod SHIFT, H, moveactive, -50 0"
        "$mainMod SHIFT, L, moveactive, 50 0"
        "$mainMod SHIFT, K, moveactive, 0 -50"
        "$mainMod SHIFT, J, moveactive, 0 50"

        "$mainMod SHIFT, h, swapwindow, l"
        "$mainMod SHIFT, l, swapwindow, r"
        "$mainMod SHIFT, k, swapwindow, u"
        "$mainMod SHIFT, j, swapwindow, d"

        "$mainMod, u, resizeactive, -50 0"
        "$mainMod, p, resizeactive, 50 0"
        "$mainMod, o, resizeactive, 0 -50"
        "$mainMod, i, resizeactive, 0 50"

        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"

        "$mainMod, S, togglespecialworkspace, magic"
        "$mainMod SHIFT, S, movetoworkspace, special:magic"
        ", Print, exec, sh -c 'grim -g \"$(slurp)\" - | tee ~/Pictures/Screenshots/$(date +\"%Y-%m-%d_%H-%M-%S\").png | wl-copy'"
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      bindel = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ", XF86MonBrightnessUp, exec, brightnessctl s 10%+"
        ", XF86MonBrightnessDown, exec, brightnessctl s 10%-"
      ];

      bindl = [
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPause, exec, playerctl play-pause"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPrev, exec, playerctl previous"
      ];

      windowrulev2 = [
        "workspace 3, class:zen"
        "workspace 4, class:steam"
        "workspace 5, class:spotify"
        "workspace 6, class:discord"

        "suppressevent maximize, class:.*"
        "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
        "opacity 0.0 override, class:^(xwaylandvideobridge)$"
        "noanim, class:^(xwaylandvideobridge)$"
        "noinitialfocus, class:^(xwaylandvideobridge)$"
        "maxsize 1 1, class:^(xwaylandvideobridge)$"
        "noblur, class:^(xwaylandvideobridge)$"
        "nofocus, class:^(xwaylandvideobridge)$"
      ];

      layerrule = [
        "blur,waybar"

        "blur,rofi"
        "ignorealpha,rofi"

        "blur,nwg-dock"
        "ignorezero,nwg-dock"

        "blur,^(swaync-control-center)$"
        "blur,^(swaync-notification-window)$"
        "ignorezero,^(swaync-control-center)$"
        "ignorezero,^(swaync-notification-window)$"
      ];
    };
  };

  # xdg.configFile."hypr/hyprpaper.conf" = {
  #   text = ''
  #     # Preload the wallpaper
  #     preload = ~/.dotfiles/wallpapers/cherry_3.png
  #
  #     # Set the wallpaper for all monitors
  #     wallpaper = ,~/.dotfiles/wallpapers/cherry_3.png
  #   '';
  # };

  # home.sessionVariables = {
  #   OSU_SDL3 = "1";
  #   # NIXOS_OZONE_WL = "1";
  #   # MOZ_ENABLE_WAYLAND = "1";
  #   # WLR_NO_HARDWARE_CURSORS = "1";
  #   # XDG_CURRENT_DESKTOP = "Hyprland";
  #   # XDG_SESSION_DESKTOP = "Hyprland";
  #   # GDK_BACKEND         = "wayland";
  #   # QT_QPA_PLATFORM     = "wayland";
  #   # SDL_VIDEODRIVER     = "wayland";
  #   # CLUTTER_BACKEND     = "wayland";
  #   # XDG_SESSION_TYPE    = "wayland";
  # };
}
