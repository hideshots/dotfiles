{ config, pkgs, ... }:

{
  nixpkgs.overlays = [
    (self: super: {
      autotiling = self.python3Packages.buildPythonPackage rec {
        pname = "autotiling";
        version = "1.9.3";
        src = self.fetchFromGitHub {
          owner = "nwg-piotr";
          repo = "autotiling";
          rev = "v1.9.3";
          sha256 = "0ag3zz4r3cwpj769m2aw3l8yj93phsydzfz02dig5z81cc025rck";
        };
        propagatedBuildInputs = [ self.python3Packages.i3ipc ];
        meta = with self.lib; {
          description = "Autotiling script for sway and i3";
          homepage = "https://github.com/nwg-piotr/autotiling";
          license = licenses.gpl3;
        };
      };
    })
  ];

  home.packages = with pkgs; [
    autotiling
  ];

  home.file.".config/i3/config".source = ./config;
  home.file.".config/picom.conf".source = ./picom.conf;
}
