{ config, ... }:

{
  imports = [ ../. ];

  networking.firewall.allowedTCPPorts = [
    config.services.sim2h-server.port
  ];

  services.sim2h-server.enable = true;
}
