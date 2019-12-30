{ lib, ... }:

{
  imports = [
    ../.
    ../automount.nix
  ];

  boot.loader.grub = {
    enable = lib.mkDefault true;
    devices = [ "/dev/sda" "/dev/sdb" ];
  };

  services.hpos-led-manager.devicePath = "/dev/ttyUSB0";
}
