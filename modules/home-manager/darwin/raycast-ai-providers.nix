# Raycast AI — shared router provider
#
# Raycast's custom-providers file (~/.config/raycast/ai/providers.yaml) is a
# hot-reloaded dotfile under $HOME/.config, not a nix-darwin-managed system
# preference, so it belongs here rather than in a nix-darwin Raycast module —
# and because it hot-reloads, no activation-triggered app restart is needed.
#
# It is NOT a plain `home.file`, for two reasons:
#
#  1. The file is not Nix-owned today — it already holds a hand-maintained
#     provider (a local model-swap proxy) this module knows nothing about.
#     `home.file` fully replaces file content, so declaring it naively would
#     silently delete that provider. Instead this activation script merges
#     BY PROVIDER ID: it drops any prior "litellm-router" entry and keeps
#     every other provider untouched, the same "existing state as base, Nix
#     wins on its own keys" shape as merge-json-settings.sh, but keyed within
#     an array instead of a flat object merge (a plain `jq -s '.[0] * .[1]'`
#     replaces the whole `providers` array wholesale — verified: it does not
#     merge array elements — so that generic script cannot be reused here).
#  2. The API key is a real secret and Raycast's schema has no environment-
#     variable indirection (confirmed against the Raycast manual and the
#     shipped providers.template.yaml — `api_keys` takes a literal value).
#     A keychain holds no internal credentials on this estate; OpenBao does.
#     So the activation script authenticates with an AppRole (ambient
#     secret-zero, same BAO_ADDR / AI_READONLY_ROLE_ID / AI_READONLY_SECRET_ID
#     convention as every other ambient OpenBao read in this ecosystem — see
#     the (removed) splunk-mcp-connect script this pattern is lifted from)
#     and reads this consumer's own virtual key from OpenBao at apply time.
#     Nothing is written to the Nix store; if the credential is unavailable
#     the script skips the merge entirely and leaves the existing file alone.
{
  config,
  lib,
  pkgs,
  litellmAliases ? [ ],
  ...
}:

let
  cfg = config.programs.raycastAi;

  keyPlaceholder = "__RAYCAST_ROUTER_API_KEY__";

  # One model per router capability alias, tools ability explicit per the
  # design decision (Vikunja 3092) — never left to Raycast's own default.
  providerAttrs = {
    id = "litellm-router";
    name = "Shared LLM Router (LiteLLM)";
    base_url = cfg.routerBaseUrl;
    api_keys.router = keyPlaceholder;
    models = map (alias: {
      id = alias;
      name = "Router — ${alias}";
      provider = "router";
      description = "Shared LiteLLM router capability alias `${alias}` (resolved upstream, never a physical model).";
      abilities = {
        temperature.supported = true;
        vision.supported = false;
        system_message.supported = true;
        tools.supported = true;
      };
    }) litellmAliases;
  };

  providerJson = pkgs.writeText "raycast-litellm-router-provider.json" (
    builtins.toJSON providerAttrs
  );

  mergeScript = pkgs.writeShellApplication {
    name = "raycast-ai-providers-merge";
    runtimeInputs = [
      pkgs.jq
      pkgs.curl
      pkgs.yj
    ];
    text = ''
      set -euo pipefail
      target="${config.home.homeDirectory}/.config/raycast/ai/providers.yaml"

      skip() {
        echo "raycast-ai-providers-merge: skipped: no router credential ($1)" >&2
        exit 0
      }

      openbao_path="${cfg.openbaoKeyPath}"
      [ -n "$openbao_path" ] || skip "programs.raycastAi.openbaoKeyPath is unset"

      bao_addr="''${BAO_ADDR:-}"
      role_id="''${AI_READONLY_ROLE_ID:-}"
      secret_id="''${AI_READONLY_SECRET_ID:-}"
      [ -n "$bao_addr" ] && [ -n "$role_id" ] && [ -n "$secret_id" ] \
        || skip "OpenBao AppRole secret-zero absent from the environment"
      bao_addr="''${bao_addr%/}"
      openbao_path="''${openbao_path#/}"

      login_response=$(jq -nc --arg role_id "$role_id" --arg secret_id "$secret_id" \
          '{role_id: $role_id, secret_id: $secret_id}' \
        | curl -fsS --max-time 10 -H "Content-Type: application/json" --data @- \
            "$bao_addr/v1/auth/approle/login" 2>/dev/null) \
        || skip "OpenBao AppRole login failed"
      bao_token=$(printf '%s' "$login_response" | jq -er '.auth.client_token // empty' 2>/dev/null) \
        || skip "OpenBao AppRole login response had no client_token"

      secret_response=$(printf 'X-Vault-Token: %s\n' "$bao_token" \
        | curl -fsS --max-time 10 -H @- "$bao_addr/v1/$openbao_path" 2>/dev/null) \
        || skip "OpenBao denied or failed to read \$openbao_path"
      api_key=$(printf '%s' "$secret_response" | jq -er '.data.data.RAYCAST_ROUTER_API_KEY // empty' 2>/dev/null) \
        || skip "OpenBao secret at \$openbao_path has no RAYCAST_ROUTER_API_KEY field"
      [ -n "$api_key" ] || skip "RAYCAST_ROUTER_API_KEY field is empty"

      mkdir -p "$(dirname "$target")"
      existing_json='{"providers":[]}'
      if [ -f "$target" ]; then
        existing_json=$(yj -y < "$target" 2>/dev/null || echo '{"providers":[]}')
      fi

      new_provider=$(jq --arg key "$api_key" '.api_keys.router = $key' "${providerJson}")

      # Keyed merge: drop any prior entry with this provider's id, keep every
      # other provider untouched (including the hand-maintained one this file
      # already carries), then append the freshly rendered one.
      merged=$(echo "$existing_json" | jq --argjson np "$new_provider" '
        .providers = ((.providers // []) | map(select(.id != $np.id))) + [$np]
      ')

      echo "$merged" | yj -jy > "$target.tmp"
      mv "$target.tmp" "$target"
    '';
  };
in
{
  options.programs.raycastAi = {
    enable = lib.mkEnableOption "the shared LiteLLM router as a Raycast AI custom provider";

    routerBaseUrl = lib.mkOption {
      type = lib.types.str;
      example = "http://127.0.0.1:4100/v1";
      description = ''
        OpenAI-compatible base URL Raycast should call (ending in `/v1`, no
        `/chat/completions` suffix per Raycast's schema) — the local proxy
        loopback or the shared router directly, whichever this host should
        use. Required when enabled; there is no default, because the real
        value is private homelab topology and a wrong default would
        silently point Raycast at nothing.
      '';
    };

    openbaoKeyPath = lib.mkOption {
      type = lib.types.str;
      example = "secret/data/ai/router-keys/raycast";
      description = ''
        OpenBao KV path holding this consumer's own LiteLLM virtual key,
        under the field `RAYCAST_ROUTER_API_KEY` — published per-consumer by
        the router's virtual-key rollout (Vikunja 3072). Read at
        `home-manager`/`darwin-rebuild` activation time using the same
        ambient AppRole secret-zero (`BAO_ADDR`, `AI_READONLY_ROLE_ID`,
        `AI_READONLY_SECRET_ID`) every other OpenBao-backed read in this
        ecosystem uses; the untrusted/interactive tier's read-only AppRole
        is the expected policy backing it. Required when enabled; there is
        no default, since the real path is deployment-specific and a wrong
        default would read the wrong consumer's key. When the credential
        cannot be read, the activation script skips the merge and leaves
        the existing file untouched rather than writing an empty key.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.routerBaseUrl != "";
        message = "programs.raycastAi.routerBaseUrl must be set when programs.raycastAi.enable is true.";
      }
      {
        assertion = cfg.openbaoKeyPath != "";
        message = "programs.raycastAi.openbaoKeyPath must be set when programs.raycastAi.enable is true.";
      }
    ];

    home.activation.raycastAiProviders = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${mergeScript}/bin/raycast-ai-providers-merge
    '';
  };
}
