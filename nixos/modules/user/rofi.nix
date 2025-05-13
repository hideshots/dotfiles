{ config, pkgs, lib, ... }:

let
  rofiDir = "${config.xdg.configHome}/rofi";
in
{
  # Spotlight-dark
  home.file."${rofiDir}/spotlight-dark.rasi" = {
    text = ''
      /* MACOS SPOTLIGHT LIKE DARK THEME FOR ROFI  */
      /* Author: Newman Sanchez (https://github.com/newmanls) */
      * {
          font:   "SF Pro";

          bg0:    #242424AA;
          bg1:    #7E7E7E80;
          bg2:    ${config.lib.stylix.colors.withHashtag.base0A};

          fg0:    #DEDEDE;
          fg1:    #FFFFFF;
          fg2:    #DEDEDE80;

          background-color:   transparent;
          text-color:         @fg0;

          margin:     0;
          padding:    0;
          spacing:    0;
      }

      window {
          background-color:   @bg0;

          location:       center;
          width:          640;
          border-radius:  8;
      }

      inputbar {
          font:       "Montserrat 20";
          padding:    12px;
          spacing:    12px;
          children:   [ icon-search, entry ];
      }

      icon-search {
          expand:     false;
          filename:   "search";
          size: 28px;
      }

      icon-search, entry, element-icon, element-text {
          vertical-align: 0.5;
      }

      entry {
          font:   inherit;

          placeholder         : "Search";
          placeholder-color   : @fg2;
      }

      message {
          border:             2px 0 0;
          border-color:       @bg1;
          background-color:   @bg1;
      }

      textbox {
          padding:    8px 24px;
      }

      listview {
          lines:      10;
          columns:    1;

          fixed-height:   false;
          border:         1px 0 0;
          border-color:   @bg1;
      }

      element {
          padding:            8px 16px;
          spacing:            16px;
          background-color:   transparent;
      }

      element normal active {
          text-color: @bg2;
      }

      element alternate active {
          text-color: @bg2;
      }

      element selected normal, element selected active {
          background-color:   @bg2;
          text-color:         @fg1;
      }

      element-icon {
          size:   1em;
      }

      element-text {
          text-color: inherit;
      }
    '';
  };

  # Launchpad
  home.file."${rofiDir}/launchpad-dark.rasi" = {
    text = ''
      /* MACOS LAUNCHPAD LIKE THEME FOR ROFI */
      /* Author: Newman Sanchez (https://github.com/newmanls) */

      * {
          font: "SF Pro";

          bg0:  #24242480;
          bg1:  #363636;
          bg2:  #f5f5f520;
          bg3:  #f5f5f540;
          bg4:  ${config.lib.stylix.colors.withHashtag.base0A};


          fg0:  #f5f5f5;
          fg1:  #f5f5f580;

          background-color: transparent;
          text-color:       @fg0;
          padding:          0px;
          margin:           0px;
      }

      window {
        fullscreen: true;
        padding: 1em;
        background-color: @bg0;
      }

      mainbox {
        padding: 8px;
      }

      inputbar {
        background-color: @bg2;
        margin:   0px calc(50% - 120px);
        padding:  2px 4px;
        spacing:  4px;
        border:         1px;
        border-radius:  2px;
        border-color:   @bg3;
        children: [icon-search,entry];
      }

      prompt {
        enabled: false;
      }

      icon-search {
        expand: false;
        filename: "search";
        vertical-align: 0.5;
      }

      entry {
        placeholder:       "Search";
        placeholder-color: @bg2;
      }

      listview {
        margin:   48px calc(50% - 560px);
        spacing:  48px;
        columns:  6;
        fixed-columns: true;
      }

      element, element-text, element-icon {
        cursor: pointer;
      }

      element {
        padding:      8px;
        spacing:      4px;
        orientation:  vertical;
        border-radius: 16px;
      }

      element selected {
        background-color: @bg4;
      }

      element-icon {
        size: 4em;
        horizontal-align: 0.5;
      }

      element-text {
        horizontal-align: 0.5;
      }
    '';
  };

  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    theme = "${rofiDir}/spotlight-dark.rasi";

    extraConfig = {
      modi       = "drun,run,window";
      terminal   = "foot";
      show-icons = true;
    };
  };
}
