{ config, pkgs, ... }: with pkgs;

let
  tmuxConfig = writeText "tmux.conf" ''
    set -g default-shell ${bashInteractive}/bin/bash
    set -g status-interval 1
    set -g status-right "#(${python3}/bin/python ${./tmux-status.py} < ${config.services.hpos-led-manager.statePath})"
    set -g status-style bg=white,fg=black
  '';

  tmuxWrapper = writeShellScriptBin "tmux" ''
    export TERM=xterm-256color
    source <( ${xterm}/bin/resize )
    ${tmux}/bin/tmux -f ${tmuxConfig}
    ${systemd}/bin/poweroff
  '';
in

{
  imports = [ ../. ];

  services.aorura-emu.enable = true;

  services.hpos-led-manager = {
    enable = true;
    devicePath = config.services.aorura-emu.path;
  };

  users.users.root.shell = "${tmuxWrapper}/bin/tmux";
}
