#!/usr/bin/env bash
# One-time, guarded refresh of lazy.nvim, Mason and nvim-treesitter after a
# Neovim upgrade. Re-running with an unchanged Neovim version + plugin specs
# is a no-op.
set -Eeuo pipefail

NVIM="$(command -v nvim 2>/dev/null || true)"
if [[ -z "$NVIM" ]]; then
    echo "nvim not found; skipping plugin refresh" >&2
    exit 0
fi

VERSION="$("$NVIM" --version | head -n 1 | sed -nE 's/^NVIM[[:space:]]+v?([0-9]+\.[0-9]+\.[0-9]+).*/\1/p')"
if [[ -z "$VERSION" ]]; then
    echo "could not determine nvim version; skipping plugin refresh" >&2
    exit 0
fi
if [[ "$(printf '%s\n%s\n' "$VERSION" "0.11.0" | sort -V | head -n 1)" != "0.11.0" ]]; then
    echo "nvim ${VERSION} is older than 0.11; skipping plugin refresh" >&2
    exit 0
fi

CONFIG_DIR="${HOME}/.config/nvim"
if [[ ! -d "${CONFIG_DIR}/lua/plugins" ]]; then
    echo "nvim plugin specs not found; skipping plugin refresh" >&2
    exit 0
fi

SPECS_HASH="$(find "${CONFIG_DIR}/lua/plugins" -type f -name '*.lua' \
    -exec cat {} + 2>/dev/null | cksum | awk '{print $1}')"
CURRENT="${VERSION}|${SPECS_HASH}"
MARKER="${HOME}/.cache/nvim-plugins-refreshed"

if [[ -f "$MARKER" ]] && [[ "$(cat "$MARKER")" == "$CURRENT" ]]; then
    echo "nvim plugins already refreshed for nvim ${VERSION}"
    exit 0
fi

echo "refreshing plugins for nvim ${VERSION}..."
"$NVIM" --headless '+Lazy! update' '+MasonUpdate' '+qa!'
# nvim-treesitter is lazy-loaded; load it explicitly before running TSUpdate.
"$NVIM" --headless '+Lazy load nvim-treesitter' '+TSUpdate' '+qa!'

mkdir -p "$(dirname "$MARKER")"
printf '%s\n' "$CURRENT" > "$MARKER"
echo "plugin refresh complete; lazy-lock.json is at ${CONFIG_DIR}/lazy-lock.json"
