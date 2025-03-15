{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware.nix
      ../common.nix
      ../../modules/system/bootloader.nix
      ../../modules/system/stylix.nix
    ];

  virtualisation.vmware.guest.enable = true;

  users.users.dev = {
    isNormalUser            = true;
    description             = "dev";
    shell                   = pkgs.zsh;
    ignoreShellProgramCheck = true;
    extraGroups             = [ "networkmanager" "wheel" ];
  };
}
