#!/usr/bin/env bash
# init.sh - Source this in your shell startup (.zshrc, .bashrc)
# Selects a WC2 character for this shell session

# Only run if not already set (prevents re-running in sub-shells)
if [[ -z "${WC2_CHARACTER:-}" ]]; then
    REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    export WC2_CHARACTER=$("$REPO_DIR/scripts/select_character.sh" 2>/dev/null || echo "Peasant")
fi
