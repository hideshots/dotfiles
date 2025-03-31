{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    sunshine
  ];

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };
}
