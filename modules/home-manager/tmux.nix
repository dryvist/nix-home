# tmux Configuration
#
# Session persistence, vi keybindings, and remote-friendly settings.
# Enables Claude Code agent teams split-pane mode and remote attach.

{ pkgs, ... }:

let
  # Auto-start script shipped by the tmux-logging plugin itself — a vendored
  # script, not a custom one. A freshly created pane is never already logging,
  # so invoking the toggle once per new pane always STARTS logging.
  #
  # The plugin scripts shell out to bare `tmux`, but a run-shell hook inherits
  # the tmux SERVER's minimal PATH (/usr/bin:/bin:/usr/sbin:/sbin) — which lacks
  # the nix-installed tmux. Without the prepend, every internal `tmux` call is a
  # 127 "command not found", and that 127 propagates out of `tmux new-session`
  # (tripping `set -o errexit` in callers such as the continuity resume script).
  tmuxLoggingToggle = "PATH=${pkgs.tmux}/bin:\$PATH ${pkgs.tmuxPlugins.logging}/share/tmux-plugins/logging/scripts/toggle_logging.sh";
in
{
  programs.tmux = {
    enable = true;
    prefix = "C-a";
    terminal = "tmux-256color";
    escapeTime = 10;
    mouse = true;
    historyLimit = 50000;
    baseIndex = 1;
    keyMode = "vi";
    customPaneNavigationAndResize = true;
    sensibleOnTop = true;
    focusEvents = true;

    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = resurrect;
        # Persists pane scrollback to ~/.tmux/resurrect/ (may contain secrets).
        # Acceptable on personal FileVault-encrypted machine for session persistence.
        extraConfig = "set -g @resurrect-capture-pane-contents 'on'";
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'
        '';
      }
      {
        plugin = logging;
        # Automatic session logging: the plugin strips ANSI codes and writes one
        # timestamped file per pane to @logging-path. Panes are auto-started via
        # the hooks in extraConfig below. Also binds manual controls
        # (prefix+Shift-P toggle, prefix+Alt-p screen capture, prefix+Alt-Shift-p
        # save full history).
        extraConfig = ''
          set -g @logging-path "$HOME/logs"
        '';
      }
      yank
    ];

    extraConfig = ''
      # Intuitive splits (inherit current path)
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # New window inherits current path
      bind c new-window -c "#{pane_current_path}"

      # Renumber windows on close
      set -g renumber-windows on

      # Aggressive resize (handles mixed-size clients)
      setw -g aggressive-resize on

      # True color support (Tc is the tmux-specific true color flag)
      set -ga terminal-overrides ",*256color*:Tc"

      # --- Mobile / Termius ergonomics ---
      # OSC52: text yanked in tmux lands in the phone's clipboard over SSH.
      set -g set-clipboard on
      # Phone soft-keyboards are slow; widen the repeat window so prefix+H/J/K/L
      # pane resizes chain without re-pressing the prefix each time.
      set -g repeat-time 600
      # The Termius keyboard bar covers the bottom rows — keep the status line
      # (and its window list) visible at the top instead.
      set -g status-position top
      # A closed session drops you to another instead of killing the SSH attach.
      set -g detach-on-destroy off
      # Match pane numbering to the base-1 window index for muscle-memory parity.
      setw -g pane-base-index 1

      # Minimal status bar
      set -g status-left " [#S] "
      set -g status-right " #H  %H:%M "
      set -g status-left-length 20
      set -g status-right-length 30

      # --- Automatic session logging (tmux-logging plugin) ---
      # Start logging on every new pane using the plugin's own toggle script.
      # A new pane is never already logging, so toggle == start (verified: no
      # double-fire between these hooks). One ANSI-stripped log per pane -> ~/logs.
      set-hook -g after-new-session  'run-shell "${tmuxLoggingToggle}"'
      set-hook -g after-new-window   'run-shell "${tmuxLoggingToggle}"'
      set-hook -g after-split-window 'run-shell "${tmuxLoggingToggle}"'
    '';
  };

  # tmux-logging writes to @logging-path (~/logs); ensure the directory exists.
  home.file."logs/.keep".text = "";
}
