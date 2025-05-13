{ config, pkgs, lib, ... }:

let
  original = builtins.readFile ./style.css;
in
{
  home.packages = with pkgs; [ swaynotificationcenter ];
  home.file.".config/swaync/config.json".source = ./config.json;
  home.file.".config/swaync/style.css" = {
    text = lib.mkAfter ''
      ${original}

      @define-color accent_color ${config.lib.stylix.colors.withHashtag.base0A};
      @define-color accent_color_hover ${config.lib.stylix.colors.withHashtag.base0A};
    '';
  };
}
