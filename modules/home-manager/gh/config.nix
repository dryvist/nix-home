# GitHub PAT keychain helpers (macOS only)
#
# Exposes `gh_pat`, `with_gh_pat`, `elevate_unlock` shell functions sourced
# from zsh initContent. See keychain-helpers.zsh for the contract.
#
# userConfig.keychain.elevateAccount  — account name on keychain items (default "ai-cli-coder")
# userConfig.keychain.elevateKeychain — keychain name without extension (default "elevate-access")

{
  pkgs,
  userConfig ? { },
  ...
}:

let
  elevateAccount = (userConfig.keychain or { }).elevateAccount or "ai-cli-coder";
  elevateKeychain = (userConfig.keychain or { }).elevateKeychain or "elevate-access";

  helpersScript = pkgs.replaceVars ./keychain-helpers.zsh {
    inherit elevateAccount elevateKeychain;
  };
in
{
  initScript = helpersScript;
}
