#!/usr/bin/env bash
# Verify that the package handler does no work when tools are already present,
# and that stale stubs from the old simulated handler are cleaned up.
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/home/.local/bin" "$TMP/bin"

CURL_LOG="$TMP/curl.log"
: > "$CURL_LOG"
cat > "$TMP/bin/curl" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$CURL_LOG"
exit 22
EOF
chmod +x "$TMP/bin/curl"

export HOME="$TMP/home"
# Keep the PATH minimal so a real ~/.local/bin/rg from the host cannot leak
# into the test and mask a missing tool.
export PATH="$TMP/bin:${HOME}/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Fake, already-installed tools. The handler must skip every network/package
# operation because these executables exist.
for binary in rg starship nvim tree-sitter; do
    if [[ "$binary" == "nvim" ]]; then
        printf '#!/bin/sh\necho "NVIM v0.12.6"\n' > "${HOME}/.local/bin/${binary}"
    else
        printf '#!/bin/sh\necho test-version\n' > "${HOME}/.local/bin/${binary}"
    fi
    chmod +x "${HOME}/.local/bin/${binary}"
done

# shellcheck source=../handlers/package_handler.sh
source "${ROOT}/handlers/package_handler.sh"

fail=0
run_twice() {
    local version="${3:-latest}"
    install_package "$1" "$2" "$version" ""
    install_package "$1" "$2" "$version" ""
}

run_twice ripgrep standalone-binary
run_twice starship standalone-binary
run_twice neovim standalone-binary 0.12.6
run_twice tree-sitter-cli standalone-binary

if [[ -s "$CURL_LOG" ]]; then
    echo "FAIL: curl was called even though every tool was already installed" >&2
    cat "$CURL_LOG" >&2
    fail=1
fi

# A zero-byte, non-executable rg stub from the old simulated handler must be
# removed, and the handler must still exit 0 (network is stubbed to fail).
rm -f "${HOME}/.local/bin/rg"
: > "${HOME}/.local/bin/rg"
if ! install_package ripgrep standalone-binary latest ""; then
    echo "FAIL: handler exited non-zero while recovering from a stale stub" >&2
    fail=1
fi
if [[ -e "${HOME}/.local/bin/rg" ]]; then
    echo "FAIL: stale zero-byte stub was not removed" >&2
    fail=1
fi

while IFS= read -r -d '' file; do
    echo "FAIL: zero-byte file left behind: $file" >&2
    fail=1
done < <(find "${HOME}/.local/bin" -type f -size 0 -print0)

if [[ "$fail" -eq 0 ]]; then
    echo "PASS: package handler is idempotent and leaves no stubs"
else
    exit 1
fi
