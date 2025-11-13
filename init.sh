#!/usr/bin/env bash
# init.sh - Source this in your shell startup (.zshrc, .bashrc)
# Selects a WC2 character for this shell session

# Only run if not already set (prevents re-running in sub-shells)
if [[ -z "${WC2_CHARACTER:-}" ]]; then
    # Get script path (works in both bash and zsh)
    if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        # Bash
        SCRIPT_PATH="${BASH_SOURCE[0]}"
    elif [[ -n "${(%):-%x}" ]]; then
        # Zsh
        SCRIPT_PATH="${(%):-%x}"
    else
        # Fallback: assume we're in the repo directory
        SCRIPT_PATH="./init.sh"
    fi

    WC2_SOUNDS_REPO_ROOT="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
    export WC2_CHARACTER=$("$WC2_SOUNDS_REPO_ROOT/scripts/select_character.sh" 2>/dev/null || echo "Peasant")
fi
