# claude-menu

Interactive bash menu and small helpers to switch [Claude Code](https://docs.anthropic.com/en/docs/claude-code) between **Anthropic API**, **Z.AI (GLM) API**, and **Claude Pro** (subscription, no API key in shell).

## What is this?

**claude-menu** is a small helper for your **Mac/Linux terminal**. It lets you choose *how* Claude Code connects to Anthropic: with a **paid Claude subscription** (Pro/Max — the same kind of account you use on claude.ai), with **Anthropic’s pay-per-use API**, or with **Z.AI’s API** (another provider). You pick a mode once, and the scripts remember it for new terminal windows.

You **do not** need to be a programmer to use it, but you should be comfortable opening **Terminal**, pasting a few commands, and editing a small config file if the guided setup asks you to. The rest of this README explains the technical details step by step.

## The three connection modes (in plain English)

| Mode | Menu | Who it’s for |
|------|------|----------------|
| **Claude Pro (subscription)** | **4** | You have a Claude **Pro/Max** (or Team) subscription and want Claude Code to use that — **not** a separate API bill. |
| **Anthropic API** | **2** | You use an **API key** from [Anthropic Console](https://console.anthropic.com/) (usage billed per token). |
| **Z.ai (GLM)** | **3** | You use a **Z.ai** key and GLM models through Claude Code’s slots. |

If you only use **Claude Pro**, you can skip API keys entirely in the shell (the setup wizard supports a “Pro only” path). API keys are only required for modes **2** and **3**.

## Quick start (minimal path)

1. Install [Claude Code](https://docs.anthropic.com/en/docs/claude-code) so the `claude` command works in your terminal.
2. Clone this repo and `cd` into it (see [Install](#install) for the exact `git clone` line).
3. Run **`./scripts/setup.sh`** and follow the prompts (or **`bun run setup`** if you use [Bun](https://bun.sh)).
4. Add the scripts to your `PATH` (see Install step 3 — usually symlinks in `~/bin`).
5. Run **`claude-menu`**, choose **4** for Claude Pro or **2**/**3** if you use an API key, then **6** to start Claude.

Optional but recommended: add **`source "$HOME/bin/claude-menu-shell-env"`** to your `~/.zshrc` so every new terminal remembers your choice (see Install step 4).

The sections below repeat these steps with more detail, troubleshooting, and optional tools.

You can change modes **without the menu** using **`claude-switch`** (optional; see [`claude-switch`](#claude-switch-optional)).

## Requirements

- Bash 4+
- `claude` on your `PATH` (Claude Code CLI)
- For API modes: `ANTHROPIC_AUTH_TOKEN` (see configuration)
- Optional: [Bun](https://bun.sh) — only if you want `bun run setup` for interactive setup (no extra npm packages; see `package.json`).

If you are unsure about Bash or `PATH`, follow [Quick start](#quick-start-minimal-path) first; you can come back here when something fails.

## Repository layout

You only need this if you browse the source or report an issue.

- `bin/` — `claude-menu`, `claude-switch`, `claude-menu-shell-env`, `claude-menu-setup` (symlink into `~/bin` if you use that pattern).
- `lib/` — shared helpers (`claude-menu-env.sh`, `claude-menu-constants.sh`, `claude-menu-modes.sh`). Scripts resolve the real path to the repo so symlinks to `bin/*` keep working; do not delete `lib/` next to `bin/`.

## Install

This is the **full** walkthrough (same content as [Quick start](#quick-start-minimal-path), with copy-paste commands and edge cases).

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

   Each time you pick a **connection mode** (**2**–**4** — Anthropic, Z.ai, or Claude Pro), the script writes `~/.config/claude-menu.generated.sh` and new shells load it automatically. **Option 4** (Claude Pro) clears API routing (e.g. `ANTHROPIC_BASE_URL`) and keeps **`ANTHROPIC_AUTH_TOKEN` and `ANTHROPIC_API_KEY` unset in the shell** so Claude Code can use your **subscription** (Anthropic’s docs: an API key in the environment overrides subscription). You can still store keys in `~/.config/claude-menu.env` (or Keychain) for when you switch back to **2** or **3**. Do not `export ANTHROPIC_API_KEY=…` **after** `claude-menu-shell-env` in `~/.zshrc`, or Pro will break again.

5. Run the menu — **only** `claude-menu` works as a bare command **after** step 3 (symlinks + `PATH`). From the repo you can always use:

   ```bash
   cd /path/to/claude-menu
   ./bin/claude-menu
   # or, if you use Bun:
   bun run menu
   ```

   If you see `command not found: claude-menu`, your shell does not yet find `~/bin` (or you have not symlinked). Use `./bin/claude-menu` or `bun run menu` until step 3 is done.

### Menu layout

| # | What it does |
|---|----------------|
| **1** | **Setup wizard** — guided: API key in a file, macOS Keychain, or “Pro only” (no key). |
| **2** | **Anthropic API** — pay-per-use API from Anthropic (needs a key). |
| **3** | **Z.ai** — choose a GLM model preset (needs a Z.ai key). |
| **4** | **Claude Pro** — use your claude.ai subscription in the terminal (no API key in the shell). |
| **5** | **Status** — see current mode and a quick network check. |
| **6** | **Start Claude** — runs `claude` with your saved settings. |
| **7** | **Exit** — leave the menu (you can still type `claude` in the terminal). |

Setup is first so new users see credentials before choosing a connection mode; Z.ai uses a single menu entry (**3**) so provider and GLM preset stay together.

## `claude-switch` (optional)

**You do not need `claude-switch`** if you are happy using **`claude-menu`** only. It is a second way to do the same thing: pick a **connection mode** and save it to `~/.config/claude-menu.generated.sh`.

### How it differs from the other scripts

| Script | What it does |
|--------|----------------|
| **`claude-menu`** | Interactive menu — pick mode with numbers, run setup, start `claude`. |
| **`claude-switch`** | **No menu** — one command + argument, e.g. `source claude-switch pro`. Same saved file as the menu. |
| **`claude-menu-shell-env`** | **Does not change** your mode — only **loads** whatever was last saved (put this in `~/.zshrc`). |

### Rules

- **Always `source` it** (or `. ~/bin/claude-switch …`), so environment variables apply to **this** terminal. If you run `./claude-switch` as a script, it runs in a **subshell** and your current shell may not see the change; the file on disk is still updated for **other** new terminals.
- **Default argument** if you omit one: `zai` (so `source claude-switch` alone switches to Z.ai).

### Arguments (same as menu options **2**–**4**)

| Argument | Same as menu | Notes |
|----------|----------------|--------|
| `direct` or `anthropic` | **2** — Anthropic API | Needs API key in env / Keychain. |
| `zai` | **3** — Z.ai, default GLM preset | Default when no argument. |
| `zai-default` or `zai-4.7` | **3** → preset 1 | Z.ai default GLM family. |
| `zai-glm5` or `zai-glm-5` | **3** → preset 2 | Z.ai GLM-5 preset. |
| `pro`, `claude-pro`, `off`, or `reset` | **4** — Claude Pro | Subscription mode; no API key in shell. |

**Examples:**

```bash
source claude-switch pro
source claude-switch direct
source claude-switch zai-glm5
```

### Stopping Z.ai globally

If you added `source claude-switch zai` to `~/.zshrc`, switch to Pro with **`claude-menu` option 4** or replace that line with `source claude-switch pro`. For a **one-off** session only, run `source claude-switch pro` in that terminal before `claude`.

## Glossary (quick reference)

| Term | Meaning |
|------|---------|
| **Terminal** | The text window where you type commands (macOS: Terminal.app, iTerm, or the terminal inside Cursor/VS Code). |
| **Shell** | The program that runs your commands; this project assumes **zsh** on macOS (default for years). |
| **`~/.zshrc`** | A config file that runs when you open a new terminal tab — add one line here to load claude-menu automatically. |
| **`PATH`** | A list of folders where the shell looks for programs; putting `claude-menu` in `~/bin` and adding `~/bin` to `PATH` lets you type `claude-menu` from anywhere. |
| **API key** | A secret string from Anthropic or Z.ai that bills usage to your **API account** (different from a Claude **website** subscription). |
| **Subscription (Pro/Max)** | Your Claude plan on claude.ai; Claude Code can use it when no API key is forcing API billing (see [Troubleshooting](#claude-code-still-shows-api-usage-billing-on-pro)). |
| **`~/.config/`** | A folder in your home directory for app settings; claude-menu stores a small **env** file and a **generated** file here (not your API key in the generated file). |
| **`claude-switch`** | Optional script: change mode from the command line **without** the menu (see [`claude-switch`](#claude-switch-optional)). Must be **sourced**. |

## Configuration

The defaults work for most people. Change these only if you know you need a custom path or integration.

| Variable | Purpose |
|----------|---------|
| `CLAUDE_MENU_CONFIG` | Optional path to env file (default: `~/.config/claude-menu.env`) |
| `CLAUDE_MENU_GENERATED` | Optional path for saved mode (default: `~/.config/claude-menu.generated.sh`), written when you choose connection modes **2–4** in the menu |
| `CLAUDE_MENU_MODE` | Written by the menu into the generated file: `direct`, `zai`, or `pro` (Pro forces no API token in the shell) |
| `CLAUDE_MENU_KEYCHAIN_SERVICE` | (macOS) Keychain item name; token loaded if `ANTHROPIC_AUTH_TOKEN` is unset |
| `ANTHROPIC_AUTH_TOKEN` | Bearer-style header for API / gateways; required for API modes (**2**–**3**); must be unset for Pro (**4**) |
| `ANTHROPIC_API_KEY` | Official env for API keys (`X-Api-Key`); **overrides subscription** if set ([docs](https://docs.anthropic.com/en/docs/claude-code/env-vars)) — Pro mode (**4**) unsets it in the shell |
| `ZAI_CLAUDE_EXTRA_KNOWN_MARKETPLACES` | Optional JSON for Z.AI plugin marketplace path (see Anthropic / Claude Code docs) |

The example file lists optional model overrides for Z.A.I.

## Troubleshooting

If something goes wrong, find the heading that matches your message or symptom. You can ignore variable names like `ANTHROPIC_AUTH_TOKEN` until you hit that error — then the table explains what to do.

### “ANTHROPIC_AUTH_TOKEN is not set” (or the menu shows the long help text)

That means nothing set `ANTHROPIC_AUTH_TOKEN` before the menu checked it. Common causes:

| Cause | What to do |
|--------|------------|
| No config file yet | Create `~/.config/claude-menu.env` (copy `config.example.env`), add `export ANTHROPIC_AUTH_TOKEN="…"`, `chmod 600` the file. |
| Line still commented | In the env file, the line must **not** start with `#`. Uncomment `export ANTHROPIC_AUTH_TOKEN=…`. |
| Keychain path incomplete | Run `./scripts/keychain-store-token.sh`, then in the env file set `CLAUDE_MENU_KEYCHAIN_SERVICE` (see `config.example.env`). Restart the menu. |
| Expecting the key in `claude-menu.generated.sh` | That file stores **mode only** (URL, models), **not** your API key — by design. |

After editing `~/.config/claude-menu.env`, run `claude-menu` again (or open a new terminal if you rely on something else sourcing that file; this menu loads it on startup). You can also run **option 1** (setup wizard); when it finishes successfully, the menu reloads your config automatically.

### Claude Code still shows “API Usage Billing” on Pro

1. In the **same** terminal before `claude`, run `env | grep -E '^ANTHROPIC_(API_KEY|AUTH_TOKEN)='` — both should be **empty** for subscription. If either is set, find what exports it (`~/.zshrc` **after** `claude-menu-shell-env`, direnv, project `.env`, Cursor’s environment, or `settings.json` → `env` in Claude Code).
2. **`ANTHROPIC_API_KEY`** is the usual culprit: many tutorials use it; Anthropic documents that it **overrides** Pro/Max subscription when set. Menu **4** clears it for the session; remove duplicate exports elsewhere.
3. **`forceLoginMethod: "console"`** in Claude Code settings forces Console (API) login — use `claudeai` for Claude.ai subscription, or run `claude auth login` without `--console` (see [CLI reference](https://docs.anthropic.com/en/docs/claude-code/cli-reference)).
4. Re-save Pro: `claude-menu` → **4**, or `source claude-switch pro`, then open a **new** terminal tab.

### Verify Pro environment (quick checks)

Run these in the **same** terminal where you start `claude` (after `source ~/.zshrc` or opening a new tab).

**1. No API credentials in the environment (expected for Pro)**

```bash
env | grep -E '^ANTHROPIC_(API_KEY|AUTH_TOKEN)='
```

No output = good. Any line here means Claude Code may still bill via API.

**2. Saved mode is Pro**

```bash
grep -E '^export CLAUDE_MENU_MODE=' ~/.config/claude-menu.generated.sh
```

You should see `export CLAUDE_MENU_MODE=pro`. If the file is missing, pick connection mode **4** once in `claude-menu`.

**3. Optional — simulate a login shell** (how some terminals start)

```bash
zsh -lic 'env | grep -E "^ANTHROPIC_(API_KEY|AUTH_TOKEN)=" || echo "OK: no ANTHROPIC API vars"'
```

**4. Find stray exports** (filenames and line numbers only; does not print secret values)

```bash
grep -nE 'ANTHROPIC_(API_KEY|AUTH_TOKEN)' ~/.zshrc ~/.zshenv ~/.zprofile ~/.config/claude-menu.env 2>/dev/null | cut -d: -f1-2
```

If a path appears, open that file: nothing should `export` those variables **after** `claude-menu-shell-env` when you want Pro.

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
