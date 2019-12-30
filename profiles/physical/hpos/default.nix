{ lib, ... }:

{
  imports = [ ../. ];

  hardware.enableRedistributableFirmware = lib.mkDefault false;

  services.hpos-led-manager.enable = lib.mkDefault true;
}
