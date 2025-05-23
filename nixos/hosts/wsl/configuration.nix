{ config, lib, pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  stylix = {
    enable = true;
    autoEnable = false;
    image = ../../../wallpapers/aletiune_6.png;
    polarity = "dark";

    homeManagerIntegration = {
      autoImport    = true;
      followSystem  = true;
    };

    override = {
      # Black-Metal 
      base00 = "#000000";
      base01 = "#121212";
      base02 = "#222222";
      base03 = "#333333";
      base04 = "#999999";
      base05 = "#c1c1c1";
      base06 = "#999999";
      base07 = "#c1c1c1";
      base0C = "#aaaaaa";
      base0D = "#888888";
      base0E = "#999999";
      base0F = "#444444";
    };
  };

  environment.systemPackages = with pkgs; [
    git
    xclip
    wl-clipboard
    nautilus
    neovim
    wget
  ];

  # vscode workaround
  programs.nix-ld = {
      enable = true;
      package = pkgs.nix-ld-rs;
  };

  wsl.enable = true;
  wsl.defaultUser = "nixos";

  users.users.nixos = {
    isNormalUser            = true;
    description             = "nixos";
    shell                   = pkgs.zsh;
    ignoreShellProgramCheck = true;
    extraGroups             = [ "networkmanager" "wheel" ];
  };

  system.stateVersion = "24.11";
}
