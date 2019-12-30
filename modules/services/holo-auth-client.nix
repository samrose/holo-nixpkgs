{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.holo-auth-client;
in

{
  options.services.holo-auth-client = {
    enable = mkEnableOption "Holo Auth Client";

    package = mkOption {
      default = pkgs.holo-auth-client;
      type = types.package;
    };
  };

  config = mkIf cfg.enable {
    systemd.services.holo-auth-client = {
      after = [ "network.target" "zerotierone.service" ];
      requires = [ "zerotierone.service" ];
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [
        hpos-config-into-base36-id
        zerotierone
      ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/holo-auth-client";
        RemainAfterExit = true;
        Type = "oneshot";
      };
    };
  };
}
