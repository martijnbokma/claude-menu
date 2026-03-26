## Learned User Preferences

- The user may prefer Dutch for explanations and terminal setup walkthroughs when working on this project.
- The user wants API keys and local env files kept out of git for a public repository; use Keychain or `~/.config/claude-menu.env` only, never commit secrets.

## Learned Workspace Facts

- `claude-menu` is a Bash project: `bin/` entrypoints (`claude-menu`, `claude-switch`, `claude-menu-shell-env`, `claude-menu-setup`) and shared helpers under `lib/`; scripts resolve the real repo root so `~/bin` symlinks keep working.
- Saved API mode is written to `~/.config/claude-menu.generated.sh`, which new shells load when `claude-menu-shell-env` is sourced from shell startup (e.g. `~/.zshrc`).
- `claude-switch` must be sourced (not executed) for exports to persist in the current shell; it shares mode logic with the menu and updates the generated file.
- First-time credential setup is available via `./scripts/setup.sh` or `claude-menu-setup` (Claude Pro–only, file-based key, or macOS Keychain).
- `ANTHROPIC_AUTH_TOKEN` is used for both Anthropic direct API and Z.AI; `config.example.env` is the tracked template—real keys stay local.
