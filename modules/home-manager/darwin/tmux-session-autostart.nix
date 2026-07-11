# Tmux "cc" Session Autostart
#
# A reboot always kills the tmux server (it's just a process) — any session
# running on it, and Termius' `tmux attach -t cc` startup command, dies with
# it. This LaunchAgent recreates an empty "cc" session at every login so it's
# always there to attach to, from Ghostty on the Mac or Termius on mobile.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.tmux-session-autostart;
  tmux = "${config.programs.tmux.package}/bin/tmux";

  ensureSessionScript = pkgs.writeShellScript "tmux-cc-session-autostart" ''
    ${tmux} has-session -t cc 2>/dev/null || ${tmux} new-session -d -s cc
  '';
in
{
  options.programs.tmux-session-autostart = {
    enable = lib.mkEnableOption "auto-create the tmux \"cc\" session at login";
  };

  config = lib.mkIf cfg.enable {
    launchd.agents.tmux-cc-session = {
      enable = true;
      config = {
        Label = "dev.local.tmux-cc-session";
        ProgramArguments = [ "${ensureSessionScript}" ];

        # Recreate at every login; the script itself is idempotent (has-session
        # check) so RunAtLoad firing more than once (e.g. a fast relaunch) is
        # harmless.
        RunAtLoad = true;
        KeepAlive = false;

        StandardOutPath = "/tmp/tmux-cc-session-autostart-stdout.log";
        StandardErrorPath = "/tmp/tmux-cc-session-autostart-stderr.log";
      };
    };
  };
}
