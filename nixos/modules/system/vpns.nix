{ pkgs, ... }:

{
  # programs.amnezia-vpn.enable = true;

  environment.systemPackages = with pkgs; [
    update-resolv-conf
    protonvpn-gui

    openvpn
    wireguard-tools
    strongswan
  ];
}
