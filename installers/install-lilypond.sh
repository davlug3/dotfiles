#!/usr/bin/env bash

set -Eeuo pipefail

if command -v lilypond &>/dev/null; then
  echo "lilypond already installed: $(lilypond --version 2>/dev/null | head -n 1)"
  exit 0
fi

VERSION="2.26.0"
NAME="lilypond-$VERSION-linux-x86_64.tar.gz"
URL="https://gitlab.com/lilypond/lilypond/-/releases/v$VERSION/downloads/$NAME"
INSTALL_DIR="$HOME/bin"
LILYPOND_DIR="$INSTALL_DIR/lilypond-$VERSION"

mkdir -p "$INSTALL_DIR"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cd "$TMP_DIR"

echo "Downloading LilyPond $VERSION..."
curl -fL -o "$NAME" "$URL"

echo "Extracting..."
tar -xzf "$NAME"

echo "Installing to $LILYPOND_DIR..."
rm -rf "$LILYPOND_DIR"
mv "lilypond-$VERSION" "$LILYPOND_DIR"

# ~/bin/lilypond -> ~/bin/lilypond-2.26.0/bin/lilypond
ln -sfn "$LILYPOND_DIR/bin/lilypond" "$INSTALL_DIR/lilypond"

export PATH="$INSTALL_DIR:$PATH"

echo "LilyPond installed: $(lilypond --version 2>/dev/null | head -n 1)"
