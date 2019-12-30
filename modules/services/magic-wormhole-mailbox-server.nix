{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.magic-wormhole-mailbox-server;
  pkg = pkgs.magic-wormhole-mailbox-server;

  python = pkg.passthru.python.withPackages (py: [ pkg py.twisted ]);
in

{
  options.services.magic-wormhole-mailbox-server = {
    enable = mkEnableOption "Magic Wormhole Mailbox Server";
  };

  config = mkIf cfg.enable {
    systemd.services.magic-wormhole-mailbox-server = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig.ExecStart = "${python}/bin/twistd --nodaemon wormhole-mailbox";
    };
  };
}
