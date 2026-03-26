#!/usr/bin/env bash
# Shared env loading for claude-menu (sourced, not executed).
# Sets CLAUDE_MENU_ROOT from this file's path (lib/ → repo root).

_claude_menu_env_self="${BASH_SOURCE[0]}"
while [[ -L "$_claude_menu_env_self" ]]; do
    _d="$(cd "$(dirname "$_claude_menu_env_self")" && pwd -P)"
    _claude_menu_env_self="$(readlink "$_claude_menu_env_self")"
    [[ $_claude_menu_env_self != /* ]] && _claude_menu_env_self="$_d/$_claude_menu_env_self"
done
CLAUDE_MENU_ROOT="$(cd "$(dirname "$_claude_menu_env_self")/.." && pwd -P)"
unset _claude_menu_env_self _d

claude_menu_source_user_config() {
    CLAUDE_MENU_CONFIG="${CLAUDE_MENU_CONFIG:-$HOME/.config/claude-menu.env}"
    if [[ -f "$CLAUDE_MENU_CONFIG" ]]; then
        # shellcheck disable=SC1090
        source "$CLAUDE_MENU_CONFIG"
    fi
}

claude_menu_load_keychain() {
    if [[ "$(uname -s)" == "Darwin" ]] && [[ -z "${ANTHROPIC_AUTH_TOKEN:-}" ]] && [[ -n "${CLAUDE_MENU_KEYCHAIN_SERVICE:-}" ]]; then
        if t="$(security find-generic-password -s "$CLAUDE_MENU_KEYCHAIN_SERVICE" -w 2>/dev/null)"; then
            export ANTHROPIC_AUTH_TOKEN="$t"
        fi
    fi
}

claude_menu_load_generated() {
    CLAUDE_MENU_GENERATED="${CLAUDE_MENU_GENERATED:-$HOME/.config/claude-menu.generated.sh}"
    if [[ -f "$CLAUDE_MENU_GENERATED" ]]; then
        # shellcheck disable=SC1090
        source "$CLAUDE_MENU_GENERATED"
    fi
}

# Re-apply ~/.config/claude-menu.env + Keychain after generated mode is sourced.
# Legacy generated files for Claude Pro (mode 3) contained `unset ANTHROPIC_AUTH_TOKEN`, which
# would wipe a key that was just loaded from the env file; credentials must win over routing.
claude_menu_reload_credentials() {
    claude_menu_source_user_config
    claude_menu_load_keychain
}

claude_menu_require_api_token() {
    claude_menu_reload_credentials
    if [[ -z "${ANTHROPIC_AUTH_TOKEN:-}" ]]; then
        local cfg="${CLAUDE_MENU_CONFIG:-$HOME/.config/claude-menu.env}"
        echo ""
        echo "❌ No API key in this session: ANTHROPIC_AUTH_TOKEN is not set."
        echo ""
        echo "Why: Options that use Anthropic or Z.ai (menu 2, 3) need a key. Claude Code reads"
        echo "     the same variable for both providers. This script never guesses a key."
        echo ""
        echo "Fix it — pick one path:"
        echo ""
        echo "  (1) Env file (most common)"
        echo "      • Create or edit: $cfg"
        echo "      • Add a line (uncommented):  export ANTHROPIC_AUTH_TOKEN=\"your-key-here\""
        echo "      • Use your Anthropic API key, or your Z.ai API key (same variable name)."
        echo "      • chmod 600 \"$cfg\""
        echo "      • Tip: copy config.example.env from this repo as a template."
        echo ""
        echo "  (2) macOS Keychain (token not stored in a plain file)"
        echo "      • From the repo:  ./scripts/keychain-store-token.sh"
        echo "      • In $cfg set:  export CLAUDE_MENU_KEYCHAIN_SERVICE=\"claude-menu-anthropic\""
        echo "      • Restart the menu so Keychain is read on startup."
        echo ""
        echo "  (3) Interactive wizard:  claude-menu option 1, or ./scripts/setup.sh  (or: bun run setup)"
        echo ""
        if [[ ! -f "$cfg" ]]; then
            echo "Note: $cfg does not exist yet — create it with step (1) or run setup (3)."
            echo ""
        elif ! grep -qE '^[[:space:]]*export[[:space:]]+ANTHROPIC_AUTH_TOKEN=' "$cfg" 2>/dev/null; then
            echo "Note: $cfg exists but has no active export ANTHROPIC_AUTH_TOKEN=... line"
            echo "      (check that the line is not commented out with #)."
            echo ""
        fi
        echo "If you only use Claude Pro (subscription) and do not need API keys in the shell, use menu option 4."
        echo ""
        return 1
    fi
    return 0
}
