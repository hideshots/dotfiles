{ config, pkgs, lib, ... }:

{
  imports =
    [
      ./hardware.nix
      ../common.nix
      ../../modules/system/xorg.nix
      ../../modules/system/wayland.nix
      ../../modules/system/bootloader.nix
      ../../modules/system/bluetooth.nix
      ../../modules/system/stylix.nix
      ../../modules/system/vpns.nix
    ];

  stylix.image = lib.mkForce ../../../wallpapers/aletiune_1.png;

  virtualisation.vmware.guest.enable = true;

  programs.nix-ld = {
    enable = true;
    package = pkgs.nix-ld-rs;
  };

  users.users.dev = {
    isNormalUser            = true;
    description             = "dev";
    shell                   = pkgs.zsh;
    ignoreShellProgramCheck = true;
    extraGroups             = [ "networkmanager" "wheel" ];
  };
}
