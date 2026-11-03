#!/usr/bin/env bash
# install-starship — starship installer via manifest package manager.
# Managed by chezmoi: installers/install-starship.sh -> ~/installers/install-starship.sh
# Refactored to rely entirely on handlers/package_handler.sh for execution.

set -Eeuo pipefail

# Source the new generic handler logic which contains process_manifest()
source "$HOME/.local/share/chezmoi/handlers/package_handler.sh"

# Define the manifest path (assuming it's relative to the source directory)
MANIFEST_PATH="$HOME/.local/share/chezmoi/manifest/dependencies.yaml"

echo "--- Running Starship installation via centralized package handler ---"

if process_manifest "$MANIFEST_PATH"; then
    echo -e "\n\e[32m[SUCCESS]\e[0m Dependency management run complete for Starship."
else
    echo -e "\n\e[31m[FAILURE]\e[0m Failed to run dependency handler. Check logs above and ensure the manifest path is correct." >&2
fi
