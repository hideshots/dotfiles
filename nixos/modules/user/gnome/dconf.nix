# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/Console" = {
      custom-font = "FiraMono Nerd Font 10";
      font-scale = 1.2;
      last-window-maximised = false;
      last-window-size = mkTuple [ 652 480 ];
      use-system-font = false;
    };

    "org/gnome/Extensions" = {
      window-width = 800;
    };

    "org/gnome/control-center" = {
      last-panel = "network";
      window-state = mkTuple [ 787 640 false ];
    };

"org/gnome/desktop/datetime" = {
      clock-format = "12h";
      clock-show-weekday = true;
    };

    "org/gnome/desktop/input-sources" = {
      sources = [ (mkTuple [ "xkb" "us" ]) (mkTuple [ "xkb" "ru" ]) ];
      xkb-options = [ "grp:win_space_toggle" ];
    };

    "org/gnome/desktop/interface" = {
      clock-format = "12h";
      clock-show-seconds = false;
      clock-show-weekday = true;
      color-scheme = "prefer-dark";
      document-font-name = "Noto Sans 11";
      font-antialiasing = "grayscale";
      monospace-font-name = "Noto Sans Mono Medium 11";
      toolkit-accessibility = false;
    };

    "org/gnome/desktop/notifications" = {
      application-children = [ "xdg-desktop-portal-gnome" ];
    };

    "org/gnome/desktop/notifications/application/org-gnome-console" = {
      application-id = "org.gnome.Console.desktop";
    };

    "org/gnome/desktop/notifications/application/xdg-desktop-portal-gnome" = {
      application-id = "xdg-desktop-portal-gnome.desktop";
    };

    "org/gnome/desktop/peripherals/mouse" = {
      accel-profile = "flat";
    };

    "org/gnome/desktop/peripherals/touchpad" = {
      two-finger-scrolling-enabled = true;
    };

"org/gnome/desktop/search-providers" = {
      sort-order = [ "org.gnome.Settings.desktop" "org.gnome.Contacts.desktop" "org.gnome.Nautilus.desktop" ];
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
      resize-with-right-button = false;
    };

    "org/gnome/evolution-data-server" = {
      migrated = true;
    };

    "org/gnome/mutter" = {
      attach-modal-dialogs = false;
      center-new-windows = false;
      edge-tiling = true;
    };

    "org/gnome/nautilus/list-view" = {
      default-column-order = [ "name" "size" "type" "owner" "group" "permissions" "date_modified" "date_accessed" "date_created" "recency" "detailed_type" ];
      default-visible-columns = [ "name" "size" "date_modified" ];
    };

    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view";
      migrated-gtk-settings = true;
      search-filter-time-type = "last_modified";
    };

    "org/gnome/nautilus/window-state" = {
      initial-size = mkTuple [ 621 550 ];
    };

    "org/gnome/settings-daemon/plugins/color" = {
      night-light-schedule-automatic = false;
    };

    "org/gnome/shell" = {
      disable-user-extensions = false;
      disabled-extensions = [ "status-icons@gnome-shell-extensions.gcampax.github.com" "native-window-placement@gnome-shell-extensions.gcampax.github.com" "launch-new-instance@gnome-shell-extensions.gcampax.github.com" ];
      enabled-extensions = [ "blur-my-shell@aunetx" "apps-menu@gnome-shell-extensions.gcampax.github.com" "places-menu@gnome-shell-extensions.gcampax.github.com" ];
      welcome-dialog-last-shown-version = "47.3";
    };

    "org/gnome/shell/extensions/blur-my-shell" = {
      applications-blur = true;
      applications-enable-all = true;
      applications-opacity = 220;
      blacklist = "@as []";
      blur = true;
      customize = true;
      enable-all = true;
      hacks-level = 2;
      settings-version = 2;
    };

    "org/gnome/shell/extensions/blur-my-shell/appfolder" = {
      blur = true;
      brightness = 0.6;
      sigma = 30;
      style-dialogs = 2;
    };

    "org/gnome/shell/extensions/blur-my-shell/applications" = {
      blur = true;
      blur-on-overview = false;
      brightness = 1.0;
      dynamic-opacity = true;
      enable-all = true;
      opacity = 219;
      sigma = 30;
    };

    "org/gnome/shell/extensions/blur-my-shell/coverflow-alt-tab" = {
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
      blur = true;
      brightness = 0.6;
      pipeline = "pipeline_default";
      sigma = 30;
      static-blur = true;
      style-dash-to-dock = 0;
    };

    "org/gnome/shell/extensions/blur-my-shell/lockscreen" = {
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/blur-my-shell/overview" = {
      blur = true;
      pipeline = "pipeline_default";
      style-components = 1;
    };

    "org/gnome/shell/extensions/blur-my-shell/panel" = {
      blur = true;
      brightness = 0.6;
      force-light-text = false;
      override-background = true;
      pipeline = "pipeline_default";
      sigma = 30;
      static-blur = true;
      style-panel = 0;
    };

    "org/gnome/shell/extensions/blur-my-shell/screenshot" = {
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/blur-my-shell/window-list" = {
      blur = true;
      brightness = 0.6;
      sigma = 32;
    };

    "org/gnome/tweaks" = {
      show-extensions-notice = false;
    };

    "org/gtk/gtk4/settings/color-chooser" = {
      custom-colors = [ (mkTuple [ 1.0 0.0 0.0 1.0 ]) (mkTuple [ 0.0 0.0 0.0 0.0 ]) ];
      selected-color = mkTuple [ true 1.0 0.0 0.0 1.0 ];
    };

    "org/gtk/gtk4/settings/file-chooser" = {
      show-hidden = true;
    };

    "org/gtk/settings/file-chooser" = {
      clock-format = "12h";
      date-format = "regular";
      location-mode = "path-bar";
      show-hidden = false;
      show-size-column = true;
      show-type-column = true;
      sidebar-width = 171;
      sort-column = "name";
      sort-directories-first = false;
      sort-order = "ascending";
      type-format = "category";
      window-position = mkTuple [ 0 0 ];
      window-size = mkTuple [ 1231 902 ];
    };

  };
}
