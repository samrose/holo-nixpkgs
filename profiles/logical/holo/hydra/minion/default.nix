{ lib, ... }:

{
  imports = [ ../. ];

  users.users.root.openssh.authorizedKeys.keys = lib.mkForce [
    ''command="nix-store --serve --write" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN5CNQRWNXgvrdFrzrQ3UsLqTTb8wX8BnY3PHKXb9s29 hydra.holo.host''
  ];
}
