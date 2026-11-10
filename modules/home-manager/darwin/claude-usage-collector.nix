# Claude Code usage collector
#
# Periodically reads local coding-agent session transcripts and pushes a small
# set of counters to a metrics store.
#
# The metrics exporter built into the agent reports cost, coarse token types,
# sessions and tool decisions. It does not report the ephemeral cache TTL
# split, thinking tokens, which work was delegated to a subagent, or how much
# context is injected before a conversation starts. Those exist only in the
# transcripts, so this reads them there.
#
# Counters are cumulative, matching the temporality the metrics store expects;
# a delta-temporality source is accepted and then silently dropped, which looks
# identical to a healthy pipeline.
#
# Repo labels resolve a transcript's working directory against the workspace
# layout under ~/git. The names of the family directories that group repos
# there are local data: the collector reads them at run time from a file this
# module does not write or manage, so it stays local and untracked.
#
#   Path:    ~/.config/claude-usage-collector/labels.json
#            (CLAUDE_USAGE_COLLECTOR_LABELS in the collector's environment
#            names a different file)
#   Schema:  { "families": ["family-a", "family-b"] }
#
# Each entry is a directory name as found at ~/git/public/<family>/<repo> or
# ~/git/private/<owner>/<family>/<repo>; a transcript below one is labelled
# <repo>. When the file is missing, unreadable or malformed the collector logs
# one warning and labels each transcript by the first directory below public/
# (below the owner, under private/) exactly as it appears on disk.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.claudeUsageCollector;

  collector = pkgs.writeShellScript "claude-usage-collector" ''
    set -uo pipefail
    LOG_FILE="${config.home.homeDirectory}/.local/log/claude-usage-collector.log"
    mkdir -p "$(dirname "$LOG_FILE")"

    # Trim the log rather than letting a 15-minute job grow it without bound.
    if [ -f "$LOG_FILE" ] && [ "$(wc -c < "$LOG_FILE")" -gt ${toString cfg.logMaxBytes} ]; then
      tail -n 200 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
    fi

    if ${pkgs.python3}/bin/python3 ${./files/claude-usage-collector.py} \
         --push ${lib.escapeShellArg cfg.endpoint} >> "$LOG_FILE" 2>&1; then
      echo "[$(date '+%Y-%m-%dT%H:%M:%S')] [INFO] push ok" >> "$LOG_FILE"
    else
      rc=$?
      # Non-zero leaves the watermark unadvanced, so the next run retries the
      # same records rather than losing them.
      echo "[$(date '+%Y-%m-%dT%H:%M:%S')] [ERROR] push failed rc=$rc" >> "$LOG_FILE"
      exit "$rc"
    fi
  '';
in
{
  options.programs.claudeUsageCollector = {
    enable = lib.mkEnableOption "periodic collection of coding-agent usage metrics";

    endpoint = lib.mkOption {
      type = lib.types.str;
      example = "https://metrics.example.com/api/v1/import/prometheus";
      description = ''
        Prometheus-exposition import endpoint to POST counters to. Required
        when the collector is enabled; there is no default, because a wrong
        default would silently publish usage data to the wrong place.
      '';
    };

    interval = lib.mkOption {
      type = lib.types.ints.positive;
      default = 900;
      description = ''
        Seconds between runs. Each run is incremental — it reads only bytes
        appended since the last successful push — so a short interval is cheap
        and a missed run costs nothing but latency.
      '';
    };

    logMaxBytes = lib.mkOption {
      type = lib.types.ints.positive;
      default = 1048576;
      description = "Trim the collector log once it exceeds this size.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.endpoint != "";
        message = "programs.claudeUsageCollector.endpoint must be set when the collector is enabled.";
      }
    ];

    launchd.agents.claude-usage-collector = {
      enable = true;
      config = {
        Label = "dev.claude-usage-collector";
        ProgramArguments = [ "${collector}" ];
        StartInterval = cfg.interval;
        # Not RunAtLoad: a login-time burst competes with activation for no
        # benefit, since the first interval arrives soon enough.
        RunAtLoad = false;
        KeepAlive = false;
        StandardOutPath = "${config.home.homeDirectory}/.local/log/claude-usage-collector.out";
        StandardErrorPath = "${config.home.homeDirectory}/.local/log/claude-usage-collector.err";
      };
    };
  };
}
