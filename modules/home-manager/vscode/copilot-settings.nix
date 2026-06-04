# VS Code GitHub Copilot Configuration
#
# This file defines comprehensive GitHub Copilot settings for VS Code.
# All settings are fully managed by Nix for reproducibility.
#
# SETTINGS CATEGORIES:
# - Authentication & General
# - Code Completions & Inline Suggestions
# - Chat & Agent Mode
# - Security & Privacy
# - Experimental Features
#
# Based on official VS Code Copilot settings reference:
# https://code.visualstudio.com/docs/copilot/reference/copilot-settings

_:

{
  # === AUTHENTICATION & GENERAL SETTINGS ===

  # Enable Copilot for specific languages
  # Set to object with language IDs as keys, boolean as values
  "github.copilot.enable" = {
    "*" = true; # Enable for all languages by default
    "plaintext" = true;
    "markdown" = true;
    "yaml" = true;
    "nix" = true;
    "python" = true;
    "javascript" = true;
    "typescript" = true;
    "rust" = true;
    "go" = true;
    "shell" = true;
  };

  # GitHub Enterprise authentication (if applicable)
  # Uncomment and configure if using GitHub Enterprise
  # "github.copilot.advanced" = {
  #   "authProvider" = "github-enterprise";
  # };

  # === CODE COMPLETIONS & INLINE SUGGESTIONS ===

  # Enable code actions from Copilot
  "github.copilot.editor.enableCodeActions" = true;

  # Enable automatic rename suggestions
  "github.copilot.renameSuggestions.triggerAutomatically" = true;

  # Next Edit Suggestions (NES) - AI-powered edit suggestions
  "github.copilot.nextEditSuggestions.enabled" = true;

  # Enable NES based on diagnostics (missing imports, etc.)
  "github.copilot.nextEditSuggestions.fixes" = true;

  # Inline suggestion display settings
  "editor.inlineSuggest.enabled" = true;
  "editor.inlineSuggest.showToolbar" = "always";

  # Enable syntax highlighting for inline completions
  "editor.inlineSuggest.syntaxHighlightingEnabled" = true;

  # Allow NES to shift code to show suggestions
  "editor.inlineSuggest.edits.allowCodeShifting" = true;

  # Show larger suggestions side-by-side
  "editor.inlineSuggest.edits.renderSideBySide" = true;

  # Font family for inline suggestions (optional)
  # "editor.inlineSuggest.fontFamily" = "monospace";

  # === CHAT & AGENT MODE SETTINGS ===

  # Show chat command in VS Code title bar
  "chat.commandCenter.enabled" = true;

  # Enable Copilot status overview
  "chat.experimental.statusIndicator.enabled" = true;

  # Enhanced context for TypeScript files
  "chat.languageContext.typescript.enabled" = true;

  # Custom instructions for PR description generation
  # "github.copilot.chat.pullRequestDescriptionGeneration.instructions" = ''
  #   Generate concise PR titles and descriptions.
  #   Focus on the "why" rather than the "what".
  # '';

  # Show related files suggestions
  "chat.renderRelatedFiles" = true;

  # Use GitHub projects as starter templates
  "github.copilot.chat.useProjectTemplates" = true;

  # Enable automatic code discovery with #codebase (preview)
  "github.copilot.chat.codesearch.enabled" = true;

  # Show recent chat history in empty state (experimental)
  "chat.emptyState.history.enabled" = false;

  # Enable sending elements from Simple Browser to chat (experimental)
  "chat.sendElementsToChat.enabled" = false;

  # Use AGENTS.md files in subfolders (experimental)
  # NOTE: Also set in vscode-settings.nix (true). This value (false) takes
  # precedence due to merge order in home.nix ("copilot wins on conflict").
  "chat.useNestedAgentsMdFiles" = false;

  # Configure custom OpenAI-compatible models (experimental)
  # "github.copilot.chat.customOAIModels" = [];

  # Suggest related files from git history (experimental)
  "github.copilot.chat.edits.suggestRelatedFilesFromGitHistory" = true;

  # Automatically diagnose and fix issues in generated code
  "github.copilot.chat.agent.autoFix" = true;

  # Enable thinking tool for more thorough reasoning
  "github.copilot.chat.agent.thinkingTool" = true;

  # Enable execute prompt feature
  "github.copilot.chat.executePrompt.enabled" = true;

  # Additional instruction folders for workspace
  # "chat.instructionsFilesLocations" = [];

  # Enable or disable agents
  "chat.agent.enabled" = true;

  # Auto-approve file edits based on patterns
  # This controls which files require confirmation before edits
  # Empty by default - all edits require confirmation
  # "chat.tools.edits.autoApprove" = [];

  # === SECURITY & PRIVACY ===

  # Disable AI features entirely (if needed)
  # "chat.disableAIFeatures" = false;

  # Note: Telemetry is controlled globally by VS Code settings
  # "telemetry.telemetryLevel" = "off";  # Managed in main VS Code config

  # === EXPERIMENTAL FEATURES ===
  # Features in preview - may change behavior

  # Enable AI-powered settings search
  "workbench.settings.showAISearchToggle" = true;

  # === MODEL SELECTION (Introduced February 2025) ===
  # Copilot CLI and VS Code now support model selection
  # Including Claude Sonnet in public preview
  # This is typically configured via the Copilot UI, not settings.json

  # === NOTES ===
  #
  # 1. Language-specific enable/disable:
  #    Use "github.copilot.enable" object to control per-language
  #
  # 2. Enterprise configuration:
  #    Set "github.copilot.advanced.authProvider" for GHE
  #
  # 3. Privacy considerations:
  #    - Copilot sends code to GitHub for suggestions
  #    - Disable entirely with "chat.disableAIFeatures" if needed
  #    - Review telemetry settings
  #
  # 4. Experimental features:
  #    - Features marked "experimental" may change
  #    - Test before enabling in production environments
  #
  # 5. Performance:
  #    - Inline suggestions may impact editor performance
  #    - Disable specific features if experiencing lag
  #
  # 6. Integration with Copilot CLI:
  #    - This configures the VS Code extension
  #    - Copilot CLI is configured separately (see copilot-permissions.nix)
  #    - Both can coexist and use the same GitHub subscription
}
