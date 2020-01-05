{ lib, ... }:

{
  imports = [
    ../.
    ../automount.nix
    ../inferred-grub.nix
  ];

  boot.loader.grub.enable = lib.mkDefault true;

  services.hpos-led-manager.devicePath = "/dev/ttyUSB0";
}
