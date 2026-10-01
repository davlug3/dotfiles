#!/usr/bin/env bash
# install-starship — pre-scripted starship installer, invocable any time.
# Managed by chezmoi: installers/install-starship.sh -> ~/installers/install-starship.sh
# Idempotent: exits 0 when starship is already on PATH.
set -Eeuo pipefail

have() { command -v "$1" >/dev/null 2>&1; }

# Install a system package using the first available package manager.
_pkg_install() {
    if have pkg; then          pkg install -y "$1"
    elif have apt-get; then    sudo apt-get update && sudo apt-get install -y "$1"
    elif have dnf; then        sudo dnf install -y "$1"
    elif have pacman; then     sudo pacman -S --noconfirm --needed "$1"
    elif have brew; then       brew install "$1"
    else
        echo "error: no supported package manager to install $1" >&2
        echo "Please install $1 manually, then re-run." >&2
        return 1
    fi
}

if have starship; then
  echo "starship already installed: $(starship --version | head -n 1)"
  exit 0
fi

echo "starship not found; installing..."

# Strategy 1: native package manager
if have apt-get || have dnf || have pacman || have brew || have pkg; then
  echo "trying package manager..."
  if _pkg_install starship 2>/dev/null; then
    echo "starship installed via package manager"
    exit 0
  fi
  echo "package manager install failed; falling back to official installer..."
fi

# Strategy 2: official starship.rs installer
# mkdir -p ensures the target directory exists (fixes "does not appear to
# be a directory" error on fresh systems where ~/.local/bin doesn't exist)
mkdir -p "${HOME}/.local/bin"
if have curl; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y -b "${HOME}/.local/bin"
elif have wget; then
  wget -qO- https://starship.rs/install.sh | sh -s -- -y -b "${HOME}/.local/bin"
else
  echo "error: need curl or wget to install starship" >&2
  exit 1
fi
[ -x "${HOME}/.local/bin/starship" ] || {
  echo "error: starship was not installed" >&2; exit 1;
}
echo "starship installed at ${HOME}/.local/bin/starship"
