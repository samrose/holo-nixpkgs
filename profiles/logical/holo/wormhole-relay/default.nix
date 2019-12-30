{
  imports = [ ../. ];

  networking.firewall.allowedTCPPorts = [ 4000 ];

  services.magic-wormhole-mailbox-server.enable = true;
}
