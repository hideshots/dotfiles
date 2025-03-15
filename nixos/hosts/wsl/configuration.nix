# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL
{ config, lib, pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
    git
    vim
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
