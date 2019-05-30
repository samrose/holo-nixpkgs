{ lib, pkgs, ... }:

let
  self = "/nix/var/nix/profiles/per-user/root/channels/holoportos";
in

{
  imports = [ ../. ];

  boot.loader.grub.splashImage = ./splash.png;
  boot.loader.timeout = 1;

  documentation.nixos.enable = false;

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };

  nix.nixPath = [
    "nixpkgs=${self}/nixpkgs"
    "nixpkgs-overlays=${self}/overlays"
    "nixos-config=/etc/nixos/configuration.nix"
    "/nix/var/nix/profiles/per-user/root/channels"
  ];

  security.sudo.wheelNeedsPassword = false;

  services.mingetty.autologinUser = "holoport";

  services.openssh.enable = true;

  services.zerotierone = {
    enable = true;
    joinNetworks = [ "e5cd7a9e1c3e8c42" ];
  };

  system.autoUpgrade = {
    enable = true;
    dates = "*:0/10";
  };

  system.stateVersion = "19.09";

  users.mutableUsers = false;

  users.users.holoport = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  users.users.support = {
    isNormalUser = true;
  };

  users.users.root.password = "";
}
