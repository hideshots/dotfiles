{ pkgs, ... }:

{
  # programs.amnezia-vpn.enable = true;

  environment.systemPackages = with pkgs; [
    protonvpn-gui
  ];
}
