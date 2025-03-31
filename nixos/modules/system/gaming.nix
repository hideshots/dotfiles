{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    gamemode
    mangohud
    lutris
    wineWowPackages.stable
    # wine64
    winetricks

    # required to fix memory allocation issues in some Source engine games
    # pkgsi686Linux.jemalloc
  ];

  programs.gamescope = {
    enable = true;
    package = pkgs.gamescope.overrideAttrs (_: { # uneven scaling fix
      NIX_CFLAGS_COMPILE = ["-fno-fast-math"];
    });
  };

  programs.gamemode.enable = true;

  # Game launchers
  hardware.graphics.enable32Bit = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };
}
