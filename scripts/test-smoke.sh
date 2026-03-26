#!/usr/bin/env bash
# Non-interactive smoke tests: bash syntax + lib/modes behaviour in an isolated HOME.
# Run from repo root: ./scripts/test-smoke.sh
# Or: bun run test

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILED=0

die() {
    echo "FAIL: $*" >&2
    FAILED=1
}

echo "== Syntax (bash -n) =="
SH_FILES=(
    "$ROOT/bin/claude-menu"
    "$ROOT/bin/claude-switch"
    "$ROOT/bin/claude-menu-shell-env"
    "$ROOT/bin/claude-menu-setup"
    "$ROOT/lib/claude-menu-env.sh"
    "$ROOT/lib/claude-menu-constants.sh"
    "$ROOT/lib/claude-menu-modes.sh"
    "$ROOT/scripts/setup.sh"
    "$ROOT/scripts/keychain-store-token.sh"
)
for f in "${SH_FILES[@]}"; do
    if [[ ! -f "$f" ]]; then
        echo "  SKIP missing $f"
        continue
    fi
    bash -n "$f" || die "bash -n $f"
    echo "  OK $(basename "$f")"
done

if command -v shellcheck &>/dev/null; then
    echo ""
    echo "== shellcheck (optional) =="
    for f in "${SH_FILES[@]}"; do
        [[ -f "$f" ]] || continue
        shellcheck -x "$f" && echo "  OK $(basename "$f")" || die "shellcheck $f"
    done
else
    echo ""
    echo "== shellcheck: skipped (install for stricter checks) =="
fi

echo ""
echo "== lib: set_mode (isolated HOME) =="
TEST_HOME="$(mktemp -d "${TMPDIR:-/tmp}/claude-menu-test.XXXXXX")"
cleanup() { rm -rf "$TEST_HOME"; }
trap cleanup EXIT

export HOME="$TEST_HOME"
mkdir -p "$HOME/.config"
export CLAUDE_MENU_CONFIG="$HOME/.config/claude-menu.env"
: >"$CLAUDE_MENU_CONFIG"
export CLAUDE_MENU_GENERATED="$HOME/.config/claude-menu.generated.sh"
export ANTHROPIC_AUTH_TOKEN="smoke-test-token"

# shellcheck disable=SC1091
source "$ROOT/lib/claude-menu-env.sh"
# shellcheck disable=SC1091
source "$ROOT/lib/claude-menu-modes.sh"

claude_menu_set_mode 1
[[ "${ANTHROPIC_BASE_URL:-}" == "$CLAUDE_MENU_URL_DIRECT" ]] || die "mode 1 ANTHROPIC_BASE_URL"
[[ "${API_TIMEOUT_MS:-}" == "$CLAUDE_MENU_API_TIMEOUT_MS" ]] || die "mode 1 API_TIMEOUT_MS"
[[ -f "$CLAUDE_MENU_GENERATED" ]] || die "mode 1 generated file missing"
echo "  OK set_mode 1 (Anthropic)"

export ANTHROPIC_AUTH_TOKEN="smoke-test-token"
claude_menu_set_mode 2
[[ "${ANTHROPIC_BASE_URL:-}" == "$CLAUDE_MENU_URL_ZAI" ]] || die "mode 2 URL"
[[ -n "${ANTHROPIC_DEFAULT_HAIKU_MODEL:-}" ]] || die "mode 2 models"
echo "  OK set_mode 2 (ZAI)"

claude_menu_set_zai_model_preset glm5
[[ "${ANTHROPIC_DEFAULT_SONNET_MODEL:-}" == "glm-5" ]] || die "preset glm5 sonnet"
grep -q 'glm-5' "$CLAUDE_MENU_GENERATED" || die "preset glm5 generated file"
echo "  OK set_zai_model_preset glm5"

claude_menu_set_mode 3
[[ -z "${ANTHROPIC_BASE_URL:-}" ]] || die "mode 3 BASE_URL unset"
[[ "${ANTHROPIC_AUTH_TOKEN:-}" == "smoke-test-token" ]] || die "mode 3 keeps ANTHROPIC_AUTH_TOKEN (routing is via unset BASE_URL)"
echo "  OK set_mode 3 (Pro)"

echo ""
echo "== lib: credentials after legacy generated (unset token) =="
# Simulate old Pro generated.sh that unset ANTHROPIC_AUTH_TOKEN; token must live in claude-menu.env
printf '%s\n' 'export ANTHROPIC_AUTH_TOKEN="legacy-restore-token"' >"$CLAUDE_MENU_CONFIG"
printf '%s\n' '# legacy' 'unset ANTHROPIC_AUTH_TOKEN' >"$CLAUDE_MENU_GENERATED"
# shellcheck disable=SC1090
source "$CLAUDE_MENU_GENERATED"
[[ -z "${ANTHROPIC_AUTH_TOKEN:-}" ]] || die "legacy file should clear token before reload"
claude_menu_reload_credentials
[[ "${ANTHROPIC_AUTH_TOKEN:-}" == "legacy-restore-token" ]] || die "reload_credentials should restore token from env file"
echo "  OK reload_credentials after legacy generated unset"

if [[ "$FAILED" -ne 0 ]]; then
    echo "" >&2
    echo "Smoke tests failed." >&2
    exit 1
fi

echo ""
echo "All smoke checks passed."
