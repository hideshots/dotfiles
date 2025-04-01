{ config, pkgs, inputs, ... }:

{
  imports = [
    ../home-common.nix
  ];

  home.username      = "dev";
  home.homeDirectory = "/home/dev";

  home.packages = with pkgs; [
    inputs.nix-gaming.packages.${system}.osu-lazer-bin
  ];

  programs.git = {
    enable = true;
    userName = "vm";
    userEmail = "dev@vmware.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  home.stateVersion  = "24.11";
}
