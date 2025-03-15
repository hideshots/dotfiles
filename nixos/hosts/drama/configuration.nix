{ config, pkgs, inputs, ... }:

{
  imports =
    [
      ./hardware.nix
      ../common.nix
      ../../modules/system/hardware/devices.nix
      ../../modules/system/hardware/nvidia.nix
      ../../modules/system/bootloader.nix
      ../../modules/system/gaming.nix
      ../../modules/system/vpns.nix
      ../../modules/system/bluetooth.nix
      ../../modules/system/stylix.nix
      ../../modules/system/qemu.nix
    ];

  boot.supportedFilesystems = [ "ntfs" ];
  fileSystems."/mnt/dev" = {
    device = "/dev/disk/by-uuid/A64C9C314C9BF9EF";
    fsType = "ntfs-3g";
    options = [ "rw" "exec" "uid=1000" "gid=1000" "umask=022" ];
  };

  fileSystems."/mnt/ssd" = {
    device = "/dev/disk/by-uuid/549AE3719AE34E54";
    fsType = "ntfs-3g";
    options = [ "rw" "exec" "uid=1000" "gid=1000" "umask=022" ];
  };

  fileSystems."/mnt/hdd" = {
    device = "/dev/disk/by-uuid/2C4877224876EA4A";
    fsType = "ntfs-3g";
    options = [ "rw" "exec" "uid=1000" "gid=1000" "umask=022" ];
  };

  # Bind mounts to make them visible in Nautilus
  fileSystems."/media/dev" = {
    device = "/mnt/dev";
    fsType = "none";
    options = [ "bind" ];
  };

  fileSystems."/media/ssd" = {
    device = "/mnt/ssd";
    fsType = "none";
    options = [ "bind" ];
  };

  fileSystems."/media/hdd" = {
    device = "/mnt/hdd";
    fsType = "none";
    options = [ "bind" ];
  };

  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
  '';
  security.polkit.enable = true;

  environment.systemPackages = with pkgs; [
    (discord-canary.override {
      withVencord = true;
    })
  ];

  users.users.drama = {
    isNormalUser            = true;
    description             = "drama";
    shell                   = pkgs.zsh;
    ignoreShellProgramCheck = true;
    extraGroups             = [ "networkmanager" "wheel" "libvirtd"];
  };
}
