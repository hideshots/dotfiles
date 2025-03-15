{ config, pkgs, inputs, ... }:

{
  imports = [
    ../home-common.nix
  ];

  home.username      = "drama";
  home.homeDirectory = "/home/drama";

  programs.git = {
    enable = true;
    userName = "drama";
    userEmail = "drama@nixos.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };
  
  home.packages = with pkgs; [
    obs-studio
    obsidian
    teams-for-linux
    chromium

    inputs.nix-gaming.packages.${system}.osu-lazer-bin
    # inputs.nix-gaming.packages.${system}.osu-stable
    prismlauncher
    rpcs3
  ];

  home.stateVersion  = "24.11";
}
