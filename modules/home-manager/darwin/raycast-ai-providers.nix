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
#     So the Nix-rendered provider JSON below carries a placeholder string
#     instead of a key, and the activation script substitutes the real
#     value read from Keychain at apply time — the key is never written to
#     the Nix store.
{
  config,
  lib,
  pkgs,
  userConfig ? { },
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

  kcAccount = (userConfig.keychain or { }).aiAccount or "";
  kcDb = (userConfig.keychain or { }).aiDb or "";

  mergeScript = pkgs.writeShellApplication {
    name = "raycast-ai-providers-merge";
    runtimeInputs = [
      pkgs.jq
      pkgs.yj
    ];
    text = ''
      set -euo pipefail
      target="${config.home.homeDirectory}/.config/raycast/ai/providers.yaml"
      mkdir -p "$(dirname "$target")"

      existing_json='{"providers":[]}'
      if [ -f "$target" ]; then
        existing_json=$(yj -y < "$target" 2>/dev/null || echo '{"providers":[]}')
      fi

      api_key="${keyPlaceholder}"
      ${lib.optionalString (kcAccount != "" && kcDb != "") ''
        if resolved=$(security find-generic-password -s RAYCAST_ROUTER_API_KEY -a "${kcAccount}" -w "${kcDb}" 2>/dev/null) \
          && [ -n "$resolved" ]; then
          api_key="$resolved"
        fi
      ''}
      if [ "$api_key" = "${keyPlaceholder}" ]; then
        echo "raycast-ai-providers-merge: RAYCAST_ROUTER_API_KEY not found in Keychain — writing a placeholder key; the router provider will not authenticate until it is set" >&2
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
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.routerBaseUrl != "";
        message = "programs.raycastAi.routerBaseUrl must be set when programs.raycastAi.enable is true.";
      }
    ];

    home.activation.raycastAiProviders = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${mergeScript}/bin/raycast-ai-providers-merge
    '';
  };
}
