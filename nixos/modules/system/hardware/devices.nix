{ pkgs, ... }:

{
  services.udev.extraRules = ''
    # WL WLMOUSE Beast Max 8K Receiver
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="36a7", ATTRS{idProduct}=="a880", MODE="0777"

    # MAD60 device: grant full access
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="373b", ATTRS{idProduct}=="105d", MODE="0777"
  '';

  hardware.opentabletdriver.enable = true;
  hardware.opentabletdriver.daemon.enable = true;
}
