{ config, pkgs, inputs, ... }:

{
  imports =
    [
      ./hardware.nix
      ../common.nix
      ../../modules/system/hardware/intel.nix
      ../../modules/system/hardware/battery.nix
      ../../modules/system/gaming.nix
      ../../modules/system/sunshine.nix
      ../../modules/system/bootloader.nix
      ../../modules/system/stylix.nix
      ../../modules/system/vpns.nix
      ../../modules/system/bluetooth.nix
    ];

  home-manager.backupFileExtension = "backup";

  users.users.lenovo = {
    isNormalUser            = true;
    description             = "lenovo";
    shell                   = pkgs.zsh;
    ignoreShellProgramCheck = true;
    extraGroups             = [ "networkmanager" "wheel" ];
  };
}
