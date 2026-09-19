# Raycast AI — shared router provider
#
# Raycast's custom-providers file (~/.config/raycast/ai/providers.yaml) is a
# hot-reloaded dotfile under $HOME/.config, not a nix-darwin-managed system
# preference, so it belongs here rather than in a nix-darwin Raycast module —
# and because it hot-reloads, no activation-triggered app restart is needed.
#
# Fully declarative: `home.file` renders the whole file from `providerAttrs`
# below, no activation script, no OpenBao read, no jq/yj/curl merge. This
# REPLACES any hand-maintained providers.yaml — home-manager refuses to
# overwrite one it doesn't already own ("... is in the way"); move or delete
# an existing file once before enabling this. No secret is involved: the
# local LiteLLM proxy this points at (`programs.litellmLocal` in nix-ai)
# checks no credential of its own, so `api_keys.router` is that proxy's own
# fixed, non-secret placeholder token, read from the SAME contract every
# other OpenAI-compatible CLI on this host already reads
# (`programs.litellmLocal.baseUrl` / `.clientToken`, via `litellmLocalDefaults`
# in flake.nix). If a host ever points this at the router directly instead of
# through the loopback proxy, override `routerBaseUrl` and give that endpoint
# a provider that DOES take a real key — this module only covers the
# no-credential loopback case.
{
  lib,
  pkgs,
  config,
  litellmAliases ? [ ],
  litellmLocalDefaults ? {
    baseUrl = "http://127.0.0.1:4100/v1";
    clientToken = "local";
  },
  ...
}:

let
  cfg = config.programs.raycastAi;

  # One model per router capability alias (the nix-ai `aliases.nix` contract
  # — the same list every other consumer on this host renders from), tools
  # ability explicit per the design decision (Vikunja 3092) — never left to
  # Raycast's own default. No `description`: not a field in Raycast's
  # providers.yaml schema (manual.raycast.com/ai/custom-providers).
  providerAttrs = {
    id = "litellm-router";
    name = "Shared LLM Router (LiteLLM)";
    base_url = cfg.routerBaseUrl;
    api_keys.router = cfg.routerApiKey;
    models = map (alias: {
      id = alias;
      name = "Router — ${alias}";
      provider = "router";
      abilities = {
        temperature.supported = true;
        vision.supported = false;
        system_message.supported = true;
        tools.supported = true;
      };
    }) litellmAliases;
  };
in
{
  options.programs.raycastAi = {
    enable = lib.mkEnableOption "the shared LiteLLM router as a Raycast AI custom provider";

    routerBaseUrl = lib.mkOption {
      type = lib.types.str;
      default = litellmLocalDefaults.baseUrl;
      example = "http://127.0.0.1:4100/v1";
      description = ''
        OpenAI-compatible base URL Raycast should call (ending in `/v1`, no
        `/chat/completions` suffix per Raycast's schema). Defaults to this
        host's local LiteLLM proxy loopback (`programs.litellmLocal.baseUrl`
        in nix-ai) — override only for a host that points Raycast at the
        shared router directly instead of through that proxy.
      '';
    };

    routerApiKey = lib.mkOption {
      type = lib.types.str;
      default = litellmLocalDefaults.clientToken;
      description = ''
        Value written to `api_keys.router`. Defaults to the local proxy's own
        placeholder client token (`programs.litellmLocal.clientToken` in
        nix-ai, currently `"local"`) — not a secret, because that proxy
        checks no credential. Override only when `routerBaseUrl` points
        somewhere that DOES require a real key.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.routerBaseUrl != "";
        message = "programs.raycastAi.routerBaseUrl must be set when programs.raycastAi.enable is true.";
      }
    ];

    home.file.".config/raycast/ai/providers.yaml".source =
      (pkgs.formats.yaml { }).generate "raycast-providers.yaml"
        {
          providers = [ providerAttrs ];
        };
  };
}
