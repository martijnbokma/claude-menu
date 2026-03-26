# claude-menu

Interactive bash menu and small helpers to switch [Claude Code](https://docs.anthropic.com/en/docs/claude-code) between **Anthropic API**, **Z.AI (GLM) API**, and **Claude Pro** (subscription, no API key in shell).

## Requirements

- Bash 4+
- `claude` on your `PATH` (Claude Code CLI)
- For API modes: `ANTHROPIC_AUTH_TOKEN` (see configuration)
- Optional: [Bun](https://bun.sh) — only if you want `bun run setup` for interactive setup (no extra npm packages; see `package.json`).

## Layout

- `bin/` — `claude-menu`, `claude-switch`, `claude-menu-shell-env`, `claude-menu-setup` (symlink into `~/bin` if you use that pattern).
- `lib/` — shared helpers (`claude-menu-env.sh`, `claude-menu-constants.sh`, `claude-menu-modes.sh`). Scripts resolve the real path to the repo so symlinks to `bin/*` keep working; do not delete `lib/` next to `bin/`.

## Install

1. Clone this repository anywhere you like, for example:

   ```bash
   git clone <your-fork-url> ~/Code/claude-menu
   ```

2. **Configure credentials** — pick one:

   **You need this for API modes** (menu **2** Anthropic and **3** Z.ai). Claude Code expects `ANTHROPIC_AUTH_TOKEN` for both providers (same variable). **Option 4** (Claude Pro) does not use a key in `~/.config`.

   **Interactive setup (easiest)** — prompts for Claude Pro–only, **file-based key**, or **macOS Keychain**:

   ```bash
   cd /path/to/claude-menu
   ./scripts/setup.sh
   ```

   With **Bun** (same prompts; runs the same shell script):

   ```bash
   cd /path/to/claude-menu
   bun run setup
   ```

   Or from your `PATH` after symlinking `bin/claude-menu-setup` (see step 3): `claude-menu-setup`. From the menu: **option 1** runs the same wizard and reloads your config in that session.

   **Manual — macOS Keychain** — token never stored in a file:

   ```bash
   cd /path/to/claude-menu
   ./scripts/keychain-store-token.sh
   mkdir -p ~/.config
   cp config.example.env ~/.config/claude-menu.env
   chmod 600 ~/.config/claude-menu.env
   # Edit ~/.config/claude-menu.env: uncomment CLAUDE_MENU_KEYCHAIN_SERVICE only
   ```

   **Manual — env file only** — copy the example, **uncomment** `export ANTHROPIC_AUTH_TOKEN=...`, paste your key, save (use `chmod 600`; never commit this file):

   ```bash
   mkdir -p ~/.config
   cp /path/to/claude-menu/config.example.env ~/.config/claude-menu.env
   chmod 600 ~/.config/claude-menu.env
   # Edit ~/.config/claude-menu.env: set your key on the ANTHROPIC_AUTH_TOKEN line (line must not start with #)
   ```

   If you see **`ANTHROPIC_AUTH_TOKEN is not set`** in the menu: the variable was not loaded — usually the config file is missing, the export line is still commented out, or Keychain is not set up. See **Troubleshooting** below.

3. Put the scripts on your `PATH`, for example:

   ```bash
   mkdir -p ~/bin
   ln -sf /path/to/claude-menu/bin/claude-menu ~/bin/claude-menu
   ln -sf /path/to/claude-menu/bin/claude-switch ~/bin/claude-switch
   ln -sf /path/to/claude-menu/bin/claude-menu-shell-env ~/bin/claude-menu-shell-env
   ln -sf /path/to/claude-menu/bin/claude-menu-setup ~/bin/claude-menu-setup
   ```

   Ensure `~/bin` is in `PATH` (e.g. in `~/.zshrc`: `export PATH="$HOME/bin:$PATH"`).

4. **Optional — remember the menu choice in every new terminal** (recommended if you use the menu as your switcher):

   Add **once** to `~/.zshrc`:

   ```bash
   source "$HOME/bin/claude-menu-shell-env"
   ```

   Each time you pick a **connection mode** (**2**–**4** — Anthropic, Z.ai, or Claude Pro), the script writes `~/.config/claude-menu.generated.sh` and new shells load it automatically. **Option 4** (Claude Pro) clears API routing in that file (e.g. `ANTHROPIC_BASE_URL`); your **API key stays in** `~/.config/claude-menu.env` (or Keychain) and is loaded again after the generated file so it is not wiped.

5. Run the menu — **only** `claude-menu` works as a bare command **after** step 3 (symlinks + `PATH`). From the repo you can always use:

   ```bash
   cd /path/to/claude-menu
   ./bin/claude-menu
   # or, if you use Bun:
   bun run menu
   ```

   If you see `command not found: claude-menu`, your shell does not yet find `~/bin` (or you have not symlinked). Use `./bin/claude-menu` or `bun run menu` until step 3 is done.

### `claude-switch` (non-interactive)

Sets the **same** environment as `claude-menu` **connection modes** (**2**–**4**; use `zai` / `zai-glm5` / `direct` / `pro` — same as picking Anthropic, Z.ai, or Pro in the menu) and writes **`~/.config/claude-menu.generated.sh`** so new terminals that `source claude-menu-shell-env` stay in sync. You must **source** it (not execute):

```bash
source claude-switch zai
source claude-switch zai-glm5   # Z.ai + GLM-5 (same as menu 3 → preset 2)
# or
. ~/bin/claude-switch direct
# Claude Pro (subscription) — same as claude-menu option 4:
source claude-switch pro
# Aliases for the same reset: off, reset, claude-pro
```

Running it as `./claude-switch` starts a subshell; exports will not persist in **that** terminal session, but the **saved** file on disk is still updated for other shells.

To **stop using Z.AI globally**: use **claude-menu option 4** (Claude Pro) if `~/.zshrc` sources `claude-menu-shell-env`, or remove any `source … claude-switch zai` line from `~/.zshrc` (or replace it with `source … claude-switch pro`). For a **one-off** session, run `source claude-switch pro` in that terminal before `claude`.

### Menu layout

| # | What it does |
|---|----------------|
| **1** | Setup wizard (key / Keychain / Pro-only stub) |
| **2** | Anthropic API (direct) |
| **3** | Z.ai API — then pick default GLM or GLM-5 |
| **4** | Claude Pro (subscription) |
| **5** | Status + connection test |
| **6** | Start `claude` with current configuration |
| **7** | Exit |

Setup is first so new users see credentials before choosing a connection mode; Z.ai uses a single menu entry (**3**) so provider and GLM preset stay together.

## Configuration

| Variable | Purpose |
|----------|---------|
| `CLAUDE_MENU_CONFIG` | Optional path to env file (default: `~/.config/claude-menu.env`) |
| `CLAUDE_MENU_GENERATED` | Optional path for saved mode (default: `~/.config/claude-menu.generated.sh`), written when you choose connection modes **2–4** in the menu |
| `CLAUDE_MENU_KEYCHAIN_SERVICE` | (macOS) Keychain item name; token loaded if `ANTHROPIC_AUTH_TOKEN` is unset |
| `ANTHROPIC_AUTH_TOKEN` | Required for API modes unless Keychain is used |
| `ZAI_CLAUDE_EXTRA_KNOWN_MARKETPLACES` | Optional JSON for Z.AI plugin marketplace path (see Anthropic / Claude Code docs) |

The example file lists optional model overrides for Z.A.I.

## Troubleshooting

### “ANTHROPIC_AUTH_TOKEN is not set” (or the menu shows the long help text)

That means nothing set `ANTHROPIC_AUTH_TOKEN` before the menu checked it. Common causes:

| Cause | What to do |
|--------|------------|
| No config file yet | Create `~/.config/claude-menu.env` (copy `config.example.env`), add `export ANTHROPIC_AUTH_TOKEN="…"`, `chmod 600` the file. |
| Line still commented | In the env file, the line must **not** start with `#`. Uncomment `export ANTHROPIC_AUTH_TOKEN=…`. |
| Keychain path incomplete | Run `./scripts/keychain-store-token.sh`, then in the env file set `CLAUDE_MENU_KEYCHAIN_SERVICE` (see `config.example.env`). Restart the menu. |
| Expecting the key in `claude-menu.generated.sh` | That file stores **mode only** (URL, models), **not** your API key — by design. |

After editing `~/.config/claude-menu.env`, run `claude-menu` again (or open a new terminal if you rely on something else sourcing that file; this menu loads it on startup). You can also run **option 1** (setup wizard); when it finishes successfully, the menu reloads your config automatically.

## Testing

**Automated (recommended)** — syntax checks and a dry run of `claude_menu_set_mode` in a **temporary HOME** (no real keys, no `~/.config` touched):

```bash
./scripts/test-smoke.sh
# or
bun run test
```

If [`shellcheck`](https://github.com/koalaman/shellcheck) is installed, the smoke script runs it too.

**Manual** — after configuring credentials:

1. `source ~/.zshrc` (or open a new terminal) if you use `claude-menu-shell-env`.
2. **Menu:** run `claude-menu` — use **1** for the setup wizard if you still need credentials; pick **2–4** for connection mode as needed; **5** (status + connection test), then **6** (start Claude) for an end-to-end check.
3. **Switch:** `source claude-switch` with `direct` / `zai` / `pro` and confirm `echo $ANTHROPIC_BASE_URL` matches expectations.
4. **Setup:** `bun run setup` or `./scripts/setup.sh` — use a throwaway key or rotate after testing.

Interactive tests are best for **UI flow**; automation covers **regressions** in `lib/` and script syntax.

## Security

- **Do not commit** `~/.config/claude-menu.env` if it contains secrets, or any file with API keys.
- `~/.config/claude-menu.generated.sh` stores **mode only** (URLs, model names, unsets); it does **not** contain your API key.
- On macOS, prefer **Keychain** (`scripts/keychain-store-token.sh` + `CLAUDE_MENU_KEYCHAIN_SERVICE`) so the token is not stored in plain text.
- This repository is for **scripts only**; agents and chat logs are not a safe place for secrets.
- If a token was ever committed or pasted in chat, **rotate it** at the provider.

## License

MIT — see [LICENSE](LICENSE).
