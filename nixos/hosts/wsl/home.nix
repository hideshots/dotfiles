{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    ../../modules/user/shell.nix
    ../../modules/user/tmux.nix
    ../../modules/user/yazi.nix
    ../../modules/user/fastfetch.nix
    ../../modules/user/nixvim/nixvim.nix
    inputs.nix-yazi-plugins.legacyPackages.x86_64-linux.homeManagerModules.default
  ];

  # Obsidian vault path override
  programs.nixvim.plugins.obsidian.settings.workspaces = lib.mkForce [
    {
      name = "Personal";
      path = "/mnt/d/Documents/Vaults/Personal";
    }
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
