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
  
  services.easyeffects.enable = true;
  
  home.packages = with pkgs; [
    obs-studio
    obsidian
    teams-for-linux
    chromium
    easyeffects

    # inputs.nix-gaming.packages.${system}.osu-lazer-bin
    # inputs.nix-gaming.packages.${system}.osu-stable
    prismlauncher
    # rpcs3
  ];

  home.stateVersion  = "24.11";
}
