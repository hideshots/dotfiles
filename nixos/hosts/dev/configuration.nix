{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware.nix
      ../common.nix
      ../../modules/system/xorg.nix
      ../../modules/system/wayland.nix
      ../../modules/system/bootloader.nix
      ../../modules/system/stylix.nix
      ../../modules/system/vpns.nix
    ];

  virtualisation.vmware.guest.enable = true;

  programs.nix-ld = {
    enable = true;
    package = pkgs.nix-ld-rs;  # For NixOS 24.05 or newer
  };

  users.users.dev = {
    isNormalUser            = true;
    description             = "dev";
    shell                   = pkgs.zsh;
    ignoreShellProgramCheck = true;
    extraGroups             = [ "networkmanager" "wheel" ];
  };
}
