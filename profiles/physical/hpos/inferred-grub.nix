{ config, lib, pkgs, ... }:

{
  boot.loader.grub.device = "/dev/inferred-grub";

  boot.loader.grub.extraPrepareConfig = ''
    ln -fs \
      $(${pkgs.utillinux}/bin/lsblk -no pkname ${config.fileSystems."/".device}) \
      ${config.boot.loader.grub.device}
  '';
}
