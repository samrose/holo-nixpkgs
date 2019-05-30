{ lib, ... }:

{
  imports = [ ../. ];

  boot.postBootCommands = ''
    mkdir -p /mnt
  '';

  documentation.enable = lib.mkDefault false;

  environment.noXlibs = lib.mkDefault true;

  security.polkit.enable = lib.mkDefault false;

  services.mingetty.autologinUser = lib.mkForce "root";

  services.udisks2.enable = lib.mkDefault false;
}
