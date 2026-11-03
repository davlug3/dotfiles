#!/usr/bin/env bash
# install-nvim — neovim installer via manifest package manager.
# Managed by chezmoi: installers/install-nvim.sh -> ~/installers/install-nvim.sh
# Refactored to rely entirely on handlers/package_handler.sh for execution.

set -Eeuo pipefail

# Resolve the handler path: prefer repo source dir, fall back to deployed path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HANDLER_PATH="$REPO_ROOT/handlers/package_handler.sh"

if [[ ! -f "$HANDLER_PATH" ]]; then
    HANDLER_PATH="$HOME/.local/share/chezmoi/handlers/package_handler.sh"
fi

if [[ ! -f "$HANDLER_PATH" ]]; then
    echo "ERROR: package_handler.sh not found at $HANDLER_PATH" >&2
    exit 1
fi

source "$HANDLER_PATH"

MANIFEST_PATH="$REPO_ROOT/manifest/dependencies.yaml"
if [[ ! -f "$MANIFEST_PATH" ]]; then
    MANIFEST_PATH="$HOME/.local/share/chezmoi/manifest/dependencies.yaml"
fi

if [[ ! -f "$MANIFEST_PATH" ]]; then
    echo "ERROR: dependencies.yaml not found at $MANIFEST_PATH" >&2
    exit 1
fi

echo "--- Running Neovim installation via centralized package handler ---"

if process_manifest "$MANIFEST_PATH"; then
    echo -e "\n\e[32m[SUCCESS]\e[0m Dependency management run complete for Neovim."
else
    echo -e "\n\e[31m[FAILURE]\e[0m Failed to run dependency handler. Check logs above." >&2
fi