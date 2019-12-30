{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.udevil ];

  services.devmon.enable = true;
}
