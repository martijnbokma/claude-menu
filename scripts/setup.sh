#!/usr/bin/env bash
# Interactive first-time setup: store your API key (macOS Keychain or ~/.config/claude-menu.env).
# Claude Code reads ANTHROPIC_AUTH_TOKEN for both Anthropic direct API and Z.AI — use the key for the provider you use.
#
# Usage: ./scripts/setup.sh
#        bash /path/to/claude-menu/scripts/setup.sh

set -euo pipefail

_setup_repo_root() {
    local s="${BASH_SOURCE[0]}"
    while [[ -L "$s" ]]; do
        local d
        d="$(cd "$(dirname "$s")" && pwd -P)"
        s="$(readlink "$s")"
        [[ $s != /* ]] && s="$d/$s"
    done
    cd "$(dirname "$s")/.." && pwd -P
}

CLAUDE_MENU_REPO="$(_setup_repo_root)"
unset _setup_repo_root

CONFIG="${CLAUDE_MENU_CONFIG:-$HOME/.config/claude-menu.env}"
KEYCHAIN_SERVICE_DEFAULT="claude-menu-anthropic"

echo ""
echo "claude-menu — setup"
echo "===================="
echo ""
echo "Claude Code uses the environment variable ANTHROPIC_AUTH_TOKEN for API billing."
echo "  • Anthropic API (menu option 2): use your Anthropic API key."
echo "  • Z.AI / GLM API (menu option 3): use your Z.AI API key (same variable name)."
echo "  • Claude Pro subscription only: no API key in the shell — pick that below."
echo ""

mkdir -p "$(dirname "$CONFIG")"

if [[ -f "$CONFIG" ]]; then
    echo "Found existing config: $CONFIG"
    read -r -p "Back it up and replace it with a new setup? [y/N]: " REPLACE
    case "${REPLACE:-}" in
        y | Y | yes | YES)
            BACKUP="${CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
            cp "$CONFIG" "$BACKUP"
            echo "Backup saved: $BACKUP"
            ;;
        *)
            echo "Aborted. Edit $CONFIG by hand or remove it and run setup again."
            exit 0
            ;;
    esac
fi

echo ""
echo "How do you want to configure API access?"
echo "  1) Claude Pro only (subscription — no API key stored here)"
echo "  2) API key in a file (~/.config/claude-menu.env, chmod 600) — works on Linux and macOS"
if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "  3) macOS Keychain (recommended on Mac — key not stored in plain text)"
    echo ""
    read -r -p "Choose [1-3]: " MODE_CHOICE
else
    echo ""
    read -r -p "Choose [1-2]: " MODE_CHOICE
fi

case "${MODE_CHOICE:-}" in
    1)
        umask 077
        {
            echo "# claude-menu — created by scripts/setup.sh — do not commit"
            echo "# Claude Pro (subscription). No ANTHROPIC_AUTH_TOKEN."
            echo "# Optional: add plugin paths; see config.example.env in the repo."
            echo ""
        } >"$CONFIG"
        chmod 600 "$CONFIG" 2>/dev/null || true
        echo ""
        echo "✅ Wrote $CONFIG (Pro-only stub)."
        ;;
    2)
        read -r -s -p "Paste your API key (input hidden): " TOKEN
        echo ""
        if [[ -z "${TOKEN}" ]]; then
            echo "Aborted (empty key)."
            exit 1
        fi
        umask 077
        {
            echo "# claude-menu — created by scripts/setup.sh — do not commit"
            printf 'export ANTHROPIC_AUTH_TOKEN=%q\n' "$TOKEN"
            echo ""
            echo "# Optional: see config.example.env in the repo for Z.A.I marketplace / model overrides."
        } >"$CONFIG"
        chmod 600 "$CONFIG" 2>/dev/null || true
        echo ""
        echo "✅ API key saved to $CONFIG (permissions: 600)."
        unset TOKEN
        ;;
    3)
        if [[ "$(uname -s)" != "Darwin" ]]; then
            echo "Keychain is only available on macOS. Run setup again and choose 1 or 2."
            exit 1
        fi
        read -r -s -p "Paste your API key (input hidden): " TOKEN
        echo ""
        if [[ -z "${TOKEN}" ]]; then
            echo "Aborted (empty key)."
            exit 1
        fi
        security delete-generic-password -a "${USER}" -s "$KEYCHAIN_SERVICE_DEFAULT" &>/dev/null || true
        security add-generic-password -a "${USER}" -s "$KEYCHAIN_SERVICE_DEFAULT" -w "$TOKEN"
        unset TOKEN
        umask 077
        {
            echo "# claude-menu — created by scripts/setup.sh — do not commit"
            echo "# Token is in macOS Keychain (not in this file)."
            printf 'export CLAUDE_MENU_KEYCHAIN_SERVICE=%q\n' "$KEYCHAIN_SERVICE_DEFAULT"
            echo ""
            echo "# Optional: see config.example.env in the repo for Z.A.I marketplace / model overrides."
        } >"$CONFIG"
        chmod 600 "$CONFIG" 2>/dev/null || true
        echo ""
        echo "✅ Key stored in Keychain (service: $KEYCHAIN_SERVICE_DEFAULT)."
        echo "✅ Wrote $CONFIG (keychain service name only)."
        ;;
    *)
        echo "Invalid choice."
        exit 1
        ;;
esac

echo ""
echo "Next steps"
echo "----------"
echo "1. Run the menu from this repo (no PATH setup needed yet):"
echo "       ./bin/claude-menu"
echo "     or:  bun run menu"
echo "     (You can run this setup again anytime from the menu: option 1.)"
echo "2. Symlink into PATH when ready (see README), e.g.:"
echo "       ln -sf \"$CLAUDE_MENU_REPO/bin/claude-menu\" \"\$HOME/bin/claude-menu\""
echo "     and ensure ~/bin is in \$PATH."
echo "3. Optional — load saved API mode in every new terminal (~/.zshrc):"
echo "       source \"\$HOME/bin/claude-menu-shell-env\""
echo ""
