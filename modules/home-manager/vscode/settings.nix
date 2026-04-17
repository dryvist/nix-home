# VS Code General Settings
#
# This file defines general VS Code settings (not GitHub Copilot-specific).
# Copilot settings are in vscode-copilot-settings.nix
#
# SETTINGS CATEGORIES:
# - Update management (Nix controls VS Code updates)
# - Git integration
# - Terminal configuration
# - Python development
# - Editor behavior
# - Extension settings
# - UI/Theme
#
# Migrated from manual settings.json backup

{ config, ... }:

let
  homeDir = config.home.homeDirectory;
in
{
  # === UPDATE MANAGEMENT ===
  # Disable all auto-update functionality (Nix manages VS Code updates via nixpkgs)
  # This prevents the "An update is ready to install" popup and helper tool prompts
  #
  # NOTE: update.mode and extensions.autoCheckUpdates are set in writable-config.nix
  # (previously injected by HM module options enableUpdateCheck/enableExtensionUpdateCheck)
  "update.showReleaseNotes" = false; # Don't show release notes after Nix updates
  "extensions.autoUpdate" = false; # Don't auto-update extensions

  # === GIT INTEGRATION ===

  "git.enableSmartCommit" = true;
  "git.confirmSync" = false;
  "git.autofetch" = "all";
  "git.autofetchPeriod" = 300;
  "git.alwaysSignOff" = true;
  "git.fetchOnPull" = true;
  "git.pullBeforeCheckout" = true;
  "git.replaceTagsWhenPull" = true;

  # Protected branches - prevent accidental commits
  "git.branchProtection" = [
    "develop"
    "main"
    "master"
  ];

  # Branch naming convention validation
  "git.branchValidationRegex" = "(bugfix|chore|feature|hotfix|release)/";

  # === TERMINAL CONFIGURATION ===

  "terminal.integrated.scrollback" = 10000;
  "terminal.integrated.persistentSessionScrollback" = 10000;
  "terminal.integrated.mouseWheelZoom" = true;
  "terminal.integrated.suggest.enabled" = true;
  "terminal.integrated.shellIntegration.environmentReporting" = true;
  "terminal.integrated.tabs.location" = "left";
  "terminal.integrated.enableMultiLinePasteWarning" = "never";

  # === PYTHON DEVELOPMENT ===

  "python.analysis.typeCheckingMode" = "standard";
  "python.analysis.autoImportCompletions" = true;
  "python.analysis.completeFunctionParens" = true;
  "python.analysis.autoFormatStrings" = true;
  "python.analysis.diagnosticMode" = "workspace";
  "python.analysis.aiHoverSummaries" = false;
  "python.analysis.enablePerfTelemetry" = true;
  "python.terminal.useEnvFile" = true;
  "python-envs.terminal.showActivateButton" = true;
  "debugpy.showPythonInlineValues" = true;

  # === EDITOR BEHAVIOR ===

  "explorer.confirmDelete" = false;
  "task.verboseLogging" = true;
  "typescript.tsserver.log" = "normal";
  "php.validate.run" = "onType";
  "markdown.extension.completion.enabled" = true;

  # === EXTENSION SETTINGS ===

  # GitLens AI configuration
  "gitlens.ai.model" = "vscode";
  "gitlens.ai.vscode.model" = "copilot:gpt-4.1";

  # NOTE: Continue extension removed - redundant with Copilot and caused dirty settings.json issue
  # (Continue auto-added yaml.schemas entries that Nix couldn't pre-declare)

  # Rainbow CSV
  "rainbow_csv.highlight_rows" = true;
  "rainbow_csv.virtual_alignment_vertical_grid" = true;
  "rainbow_csv.csv_lint_detect_trailing_spaces" = true;
  "rainbow_csv.comment_prefix" = "#";

  # === CHAT/AI SETTINGS ===

  # Custom instruction file locations
  "chat.instructionsFilesLocations" = {
    ".github/instructions" = true;
    "${homeDir}/.aitk/instructions/" = true;
  };

  # Enable nested agent MD files
  "chat.useNestedAgentsMdFiles" = true;
  "chat.agentSessionsViewLocation" = "view";

  # NOTE: Copilot-specific settings (github.copilot.*) are in vscode-copilot-settings.nix

  # Auto-approve safe terminal commands in chat
  "chat.tools.terminal.autoApprove" = {
    "brew --prefix" = true;
    "brew list" = true;
    "command -v" = true;
    "launchctl bootout" = true;
    "launchctl list" = true;
    "launchctl print" = true;
    "python --version" = true;
    "python3 --version" = true;
    "source" = true;
  };

  # === UI/THEME ===

  "workbench.colorTheme" = "GitHub Dark Default";
}
