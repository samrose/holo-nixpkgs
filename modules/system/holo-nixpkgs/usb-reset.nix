{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.system.holo-nixpkgs.usbReset;
  checkUsbReset = pkgs.writeShellScriptBin "check-usb-reset" ''
    if [ -f "$1/${cfg.filename}" ]; then
      rm -f "$1/${cfg.filename}"
      ${pkgs.hpos-reset}/bin/hpos-reset
    fi
  '';

in {
  options = {
    system.holo-nixpkgs.usbReset = {
      enable = mkEnableOption "resetting when a special USB drive is connected";

      filename = mkOption {
        description = "Name of the file to look for.";
        type = types.str;
      };
    };
  };

  config = mkIf cfg.enable {
    services.automount.execOnDrive = [ "${checkUsbReset}/bin/check-usb-reset %d" ];
  };
}
