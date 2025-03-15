{ config, pkgs, ... }:

{
  programs.hyprlock = {
    enable = true;
    package = pkgs.hyprlock;
    settings = {
      indicator = true;
      clock = true;
      timestr = "%R";
      datestr = "%a, %e of %B";
    };
    extraConfig = ''
      # For example, to add a custom shape or background settings:
      # background { color = "#1d1f21"; }
    '';
  };
}
