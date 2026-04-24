# Shell Aliases
#
# Organized by category. Imported by home.nix for programs.zsh.shellAliases
#
# SUDO REQUIREMENTS:
# - Commands that modify system state (darwin-rebuild) REQUIRE sudo
# - Commands that read/inspect (docker ps, git status) do NOT need sudo
# - User config files (~/.config) should NOT use sudo
#
# Platform: macOS (BSD ls flags used)

{
  # ===========================================================================
  # Directory Listing (macOS/BSD ls)
  # ===========================================================================
  # -a: show hidden files
  # -h: human-readable sizes
  # -l: long format
  # -F: append type indicator (/ for dirs, * for executables)
  # -G: colorized output (macOS BSD ls)
  # -D: date format (macOS BSD ls)
  ll = "ls -ahlFG -D '%Y-%m-%d %H:%M:%S'";
  llt = "ls -ahltFG -D '%Y-%m-%d %H:%M:%S'"; # sorted by time
  lls = "ls -ahlsFG -D '%Y-%m-%d %H:%M:%S'"; # show size
  "ll@" = "ls -@ahlFG -D '%Y-%m-%d %H:%M:%S'"; # show extended attributes (macOS)

  # ===========================================================================
  # Docker (no sudo needed - user in docker group)
  # ===========================================================================
  dps = "docker ps -a"; # List all containers
  dcu = "docker compose up -d"; # Start compose stack detached
  dcd = "docker compose down"; # Stop compose stack

  # ===========================================================================
  # Nix / Darwin
  # ===========================================================================
  # REQUIRES SUDO: darwin-rebuild modifies system-level configurations
  # This activates both system (nix-darwin) and user (home-manager) configs
  # Usage: d-r            # darwin-rebuild switch (standard rebuild)
  d-r = "sudo darwin-rebuild switch --flake .";

  # NO SUDO: Updates flake.lock to latest nixpkgs (must commit before d-r)
  # Usage: nf-u            # update flake in current directory
  nf-u = "nix flake update --flake .";

  # ===========================================================================
  # Python
  # ===========================================================================
  # Use macOS system Python 3 (no sudo needed)
  python = "python3";

  # ===========================================================================
  # Archive (macOS-friendly tar)
  # ===========================================================================
  # COPYFILE_DISABLE=1: don't include macOS resource forks (portable across BSD/GNU tar)
  # --exclude='.DS_Store': skip Finder metadata files
  tgz = "COPYFILE_DISABLE=1 tar --exclude='.DS_Store' -czf";

  # ===========================================================================
  # AWS (aws-vault for credential management)
  # ===========================================================================
  # aws-vault stores credentials in macOS Keychain and provides temporary
  # session credentials to commands. Always use aws-vault exec for AWS CLI.
  #
  # Usage:
  #   av default -- aws s3 ls        # Run command with default profile
  #   av terraform -- terraform plan # Run terraform with specific profile
  #   avl                            # List all profiles in vault
  #   avd aws sts get-caller-identity # Quick check with default profile
  av = "aws-vault exec"; # Execute command with profile credentials
  avl = "aws-vault list"; # List profiles stored in vault
  avd = "aws-vault exec default --"; # Execute with default profile
  ava = "aws-vault add"; # Add new profile credentials to vault
  avr = "aws-vault remove"; # Remove profile from vault

  # ===========================================================================
  # AI CLI Tools (Claude)
  # ===========================================================================
  # d-claude, tf-claude, claude-latest, claude-d, claude-latest-d and related
  # Claude-specific wrappers now live in nix-ai's modules/ai-aliases.zsh
  # (sourced by programs.zsh.initContent via nix-ai's modules/ai-shell.nix).
  # The MLX aliases below stay here — they configure the local MLX dev env
  # that lives in nix-home, not Claude Code.

  # ===========================================================================
  # tmux (session management)
  # ===========================================================================
  ta = "tmux attach -t"; # Attach to named session
  tl = "tmux list-sessions"; # List active sessions
  tn = "tmux new -s"; # Create named session

  # ===========================================================================
  # MLX (Apple Silicon ML Inference Server)
  # ===========================================================================
  # On-demand MLX inference — no LaunchAgent, started manually when needed.
  # Port 11435 avoids conflicts: Ollama (:11434), Open WebUI (:8080).
  # mlx-server dir lives at ~/git/nix-ai/main/mlx-server/.
  #
  # First-time setup: run `mlx-env` once to create the venv and install packages.
  # Subsequent use: mlx-coder / mlx-rag source the existing venv directly.
  #
  # mlx-update: upgrades all MLX packages in-place (update uv.lock, then sync venv).
  #
  mlx-env = "cd ~/git/nix-ai/main/mlx-server && nix develop";
  mlx-coder = "cd ~/git/nix-ai/main/mlx-server && source .venv/bin/activate && mlx_lm.server --model mlx-community/Qwen2.5-Coder-32B-Instruct-4bit --port 11435 --host 127.0.0.1";
  mlx-rag = "cd ~/git/nix-ai/main/mlx-server && source .venv/bin/activate && mlx_lm.server --model mlx-community/c4ai-command-r-plus-08-2024-4bit --port 11435 --host 127.0.0.1";
  mlx-update = "cd ~/git/nix-ai/main/mlx-server && nix develop --command bash -c 'uv lock --upgrade && uv sync'";
}
