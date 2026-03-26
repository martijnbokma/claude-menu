#!/usr/bin/env bash
# Single source of truth for API URLs, timeouts, and Z.AI defaults (sourced, not executed).

CLAUDE_MENU_URL_DIRECT="https://api.anthropic.com"
CLAUDE_MENU_URL_ZAI="https://api.z.ai/api/anthropic"
CLAUDE_MENU_API_TIMEOUT_MS="3000000"
CLAUDE_MENU_ZAI_DEFAULT_HAIKU="glm-4.5-air"
CLAUDE_MENU_ZAI_DEFAULT_SONNET="glm-4.7"
CLAUDE_MENU_ZAI_DEFAULT_OPUS="glm-4.7"
# Preset when choosing "GLM-5" in the menu (api.z.ai — IDs may change; override in claude-menu.env if needed)
CLAUDE_MENU_ZAI_PRESET_GLM5_HAIKU="glm-4.5-air"
CLAUDE_MENU_ZAI_PRESET_GLM5_SONNET="glm-5"
CLAUDE_MENU_ZAI_PRESET_GLM5_OPUS="glm-5"
CLAUDE_MENU_ZAI_PLUGINS_JSON='{"glm-plan-usage@zai-coding-plugins": true}'
