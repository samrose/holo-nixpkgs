{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.holo-envoy;
in

{
  options.services.holo-envoy = {
    enable = mkEnableOption "Holo Envoy";

    package = mkOption {
      default = pkgs.holo-envoy;
      type = types.package;
    };
  };

  config = mkIf cfg.enable {
    systemd.services.holo-envoy = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/holo-envoy";
      };
    };
  };
}