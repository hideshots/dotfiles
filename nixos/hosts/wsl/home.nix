{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    ../../modules/user/shell.nix
    ../../modules/user/tmux.nix
    ../../modules/user/yazi.nix
    ../../modules/user/nixvim/nixvim.nix
    inputs.nix-yazi-plugins.legacyPackages.x86_64-linux.homeManagerModules.default
  ];

  stylix.targets = {
    kitty = { enable = true; };
    nixvim = { 
      enable = true;
      transparentBackground.main = true;
    };
  };

  programs.git = {
    enable = true;
    userName = "wsl";
    userEmail = "wsl@nixos.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  home.packages = with pkgs; [
  ];

  home = {
    username      = "nixos";
    homeDirectory = "/home/nixos";
    stateVersion  = "24.11";
  };
}
