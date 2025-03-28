{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    sunshine
  ];

  services.sunshine = {
    enable = true;
    autoStart = false;
    capSysAdmin = true;
    openFirewall = true;
  };
}
