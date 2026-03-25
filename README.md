# claude-menu

Interactive bash menu and small helpers to switch [Claude Code](https://docs.anthropic.com/en/docs/claude-code) between **Anthropic API**, **Z.AI (GLM) API**, and **Claude Pro** (subscription, no API key in shell).

## Requirements

- Bash 4+
- `claude` on your `PATH` (Claude Code CLI)
- For API modes: `ANTHROPIC_AUTH_TOKEN` (see configuration)

## Install

1. Clone this repository anywhere you like, for example:

   ```bash
   git clone <your-fork-url> ~/Code/claude-menu
   ```

2. Configure credentials (pick one):

   **macOS Keychain (recommended)** — token never stored in a file:

   ```bash
   cd /path/to/claude-menu
   ./scripts/keychain-store-token.sh
   mkdir -p ~/.config
   cp config.example.env ~/.config/claude-menu.env
   chmod 600 ~/.config/claude-menu.env
   # Edit ~/.config/claude-menu.env: uncomment CLAUDE_MENU_KEYCHAIN_SERVICE only
   ```

   **Env file only** — copy the example and set `export ANTHROPIC_AUTH_TOKEN=...` (use `chmod 600`; never commit this file):

   ```bash
   mkdir -p ~/.config
   cp /path/to/claude-menu/config.example.env ~/.config/claude-menu.env
   chmod 600 ~/.config/claude-menu.env
   ```

3. Put the scripts on your `PATH`, for example:

   ```bash
   mkdir -p ~/bin
   ln -sf /path/to/claude-menu/bin/claude-menu ~/bin/claude-menu
   ln -sf /path/to/claude-menu/bin/claude-switch ~/bin/claude-switch
   ```

   Ensure `~/bin` is in `PATH` (e.g. in `~/.zshrc`: `export PATH="$HOME/bin:$PATH"`).

4. Run:

   ```bash
   claude-menu
   ```

### `claude-switch` (non-interactive)

This script only sets environment variables in the **current shell**. You must **source** it:

```bash
source claude-switch zai
# or
. ~/bin/claude-switch direct
```

Running it as `./claude-switch` starts a subshell; exports will not persist in your terminal.

## Configuration

| Variable | Purpose |
|----------|---------|
| `CLAUDE_MENU_CONFIG` | Optional path to env file (default: `~/.config/claude-menu.env`) |
| `CLAUDE_MENU_KEYCHAIN_SERVICE` | (macOS) Keychain item name; token loaded if `ANTHROPIC_AUTH_TOKEN` is unset |
| `ANTHROPIC_AUTH_TOKEN` | Required for API modes unless Keychain is used |
| `ZAI_CLAUDE_EXTRA_KNOWN_MARKETPLACES` | Optional JSON for Z.AI plugin marketplace path (see Anthropic / Claude Code docs) |

The example file lists optional model overrides for Z.A.I.

## Security

- **Do not commit** `~/.config/claude-menu.env` if it contains secrets, or any file with API keys.
- On macOS, prefer **Keychain** (`scripts/keychain-store-token.sh` + `CLAUDE_MENU_KEYCHAIN_SERVICE`) so the token is not stored in plain text.
- This repository is for **scripts only**; agents and chat logs are not a safe place for secrets.
- If a token was ever committed or pasted in chat, **rotate it** at the provider.

## License

MIT — see [LICENSE](LICENSE).
