{ config, pkgs, inputs, lib, ... }:

{
  imports =
    [
      ./hardware.nix
      ../common.nix
      ../../modules/system/xorg.nix
      ../../modules/system/wayland.nix
      ../../modules/system/hardware/intel.nix
      # ../../modules/system/hardware/battery.nix
      ../../modules/system/gaming.nix
      ../../modules/system/sunshine.nix
      ../../modules/system/bootloader.nix
      ../../modules/system/stylix.nix
      ../../modules/system/vpns.nix
      ../../modules/system/bluetooth.nix
    ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  stylix.image = lib.mkForce ../../../wallpapers/aletiune_6.png;

  hardware.sensor.iio.enable = true;
  programs.iio-hyprland.enable = true;

  home-manager.backupFileExtension = "backup";

  users.users.lenovo = {
    isNormalUser            = true;
    description             = "lenovo";
    shell                   = pkgs.zsh;
    ignoreShellProgramCheck = true;
    extraGroups             = [ "networkmanager" "wheel" ];
  };
}
