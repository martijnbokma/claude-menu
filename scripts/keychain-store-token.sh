#!/usr/bin/env bash
# One-time: store API token in macOS Keychain (encrypted at rest, not in git).
# Usage: ./scripts/keychain-store-token.sh [service-name]
# Default service name: claude-menu-anthropic
#
# Then in ~/.config/claude-menu.env set:
#   export CLAUDE_MENU_KEYCHAIN_SERVICE="claude-menu-anthropic"

set -euo pipefail

SERVICE="${1:-claude-menu-anthropic}"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This script is for macOS Keychain only."
    exit 1
fi

read -r -s -p "Paste API token (input hidden): " TOKEN
echo ""

if [[ -z "${TOKEN}" ]]; then
    echo "Aborted (empty token)."
    exit 1
fi

# Replace existing item with same service name if present
security delete-generic-password -a "${USER}" -s "$SERVICE" &>/dev/null || true
security add-generic-password -a "${USER}" -s "$SERVICE" -w "$TOKEN"

echo "Stored in Keychain as service: $SERVICE"
echo "Add to ~/.config/claude-menu.env:"
echo "  export CLAUDE_MENU_KEYCHAIN_SERVICE=\"$SERVICE\""
