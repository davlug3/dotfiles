#!/usr/bin/env bash
# handlers/package_handler.sh
# Generic, idempotent package handler for the manifest-driven dotfiles.
#
# Safe to source: this module does not change the caller's shell options.
# Direct execution enables strict mode in the guard at the bottom.
#
# USAGE (sourced):
#   source handlers/package_handler.sh
#   process_manifest manifest/dependencies.yaml [package-name-filter]
#
# USAGE (direct):
#   bash handlers/package_handler.sh manifest/dependencies.yaml [package-name-filter]

log_info() { printf '%s\n' "$*"; }
log_warn() { printf 'warning: %s\n' "$*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

# Map manifest package names to the executable that proves installation.
binary_for_package() {
    case "$1" in
        ripgrep)                 printf 'rg' ;;
        neovim)                  printf 'nvim' ;;
        tree-sitter-cli|tree-sitter) printf 'tree-sitter' ;;
        *)                       printf '%s' "$1" ;;
    esac
}

# The old simulated handler left empty, non-executable stubs behind. Remove
# them so a real install can take their place, but never touch a real binary.
remove_stale_stub() {
    local package="$1" path=""
    case "$package" in
        ripgrep)  path="${HOME}/.local/bin/rg" ;;
        starship) path="${HOME}/.local/bin/starship" ;;
    esac
    if [[ -n "$path" && -f "$path" && ! -x "$path" && ! -s "$path" ]]; then
        rm -f "$path"
        log_warn "removed invalid stub: ${path}"
    fi
}

package_installed() {
    local package="$1" type="${2:-}"
    remove_stale_stub "$package"
    if [[ "$type" == "git-clone" ]]; then
        [[ -d "${HOME}/.local/share/${package}/.git" ]]
        return
    fi
    have "$(binary_for_package "$package")"
}

# Copy into a temp file in the destination directory, then move into place so
# readers never observe a partially written binary.
atomic_install() {
    local source="$1" destination="$2" tmp
    mkdir -p "$(dirname "$destination")"
    tmp=$(mktemp "${destination}.XXXXXX")
    if cp "$source" "$tmp" && chmod 0755 "$tmp"; then
        mv -f "$tmp" "$destination"
        return 0
    fi
    rm -f "$tmp"
    return 1
}

# ---------------------------------------------------------------------------
# Per-type installers. Each runs in a subshell so traps and PATH changes stay
# local and can never leak into the caller.
# ---------------------------------------------------------------------------

install_ripgrep() (
    set -Eeuo pipefail
    if have rg; then
        log_info "ripgrep already installed: $(rg --version | head -n 1)"
        exit 0
    fi

    local os arch target tag="" resp attempt version asset url tmpdir rgbin
    os="$(uname -s)"
    arch="$(uname -m)"
    case "${os}-${arch}" in
        Linux-x86_64|Linux-amd64)   target="x86_64-unknown-linux" ;;
        Linux-aarch64|Linux-arm64)  target="aarch64-unknown-linux" ;;
        Darwin-arm64)               target="aarch64-apple-darwin" ;;
        Darwin-x86_64|Darwin-amd64) target="x86_64-apple-darwin" ;;
        *)
            log_warn "ripgrep: unsupported platform ${os}-${arch}; skipping"
            exit 0
            ;;
    esac

    # Resolve the latest tag. The API returns one JSON line, so match the
    # tag_name field explicitly instead of greedily grabbing the last quote.
    for attempt in 1 2 3; do
        tag=""
        if resp=$(curl -fsSL --max-time 60 \
            https://api.github.com/repos/BurntSushi/ripgrep/releases/latest 2>/dev/null); then
            tag=$(printf '%s\n' "$resp" \
                | sed -nE 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' \
                | head -n 1)
            if [[ "$tag" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+ ]]; then
                break
            fi
            log_warn "ripgrep: unexpected release tag '${tag}' from API; retrying"
        else
            log_warn "ripgrep: API attempt ${attempt} failed; retrying"
        fi
        [[ "$attempt" -lt 3 ]] && sleep 2
    done
    if [[ -z "$tag" ]]; then
        log_warn "ripgrep: could not resolve release tag; skipping"
        exit 0
    fi

    version="${tag#v}"
    # Upstream musl assets omit the "gnu" triple component.
    if [[ "$os" == "Linux" ]]; then
        asset="ripgrep-${version}-${target}-musl.tar.gz"
    else
        asset="ripgrep-${version}-${target}.tar.gz"
    fi
    url="https://github.com/BurntSushi/ripgrep/releases/download/${tag}/${asset}"

    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT
    log_info "Downloading ripgrep ${tag} (${asset})..."
    if ! curl -fSL --max-time 120 "$url" -o "${tmpdir}/rg.tar.gz"; then
        log_warn "ripgrep: download failed (${url}); skipping"
        exit 0
    fi
    if ! tar -xzf "${tmpdir}/rg.tar.gz" -C "$tmpdir"; then
        log_warn "ripgrep: could not extract archive; skipping"
        exit 0
    fi
    rgbin=$(find "$tmpdir" -maxdepth 2 -type f -name rg | head -n 1)
    if [[ -z "$rgbin" ]]; then
        log_warn "ripgrep: rg binary not found in archive; skipping"
        exit 0
    fi
    if atomic_install "$rgbin" "${HOME}/.local/bin/rg"; then
        log_info "ripgrep installed at ${HOME}/.local/bin/rg"
    else
        log_warn "ripgrep: could not install binary; skipping"
    fi
)

install_starship() (
    set -Eeuo pipefail
    if have starship; then
        log_info "starship already installed"
        exit 0
    fi

    local tmpdir
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT
    log_info "Installing starship..."
    if curl -fsSL --max-time 60 https://starship.rs/install.sh \
        -o "${tmpdir}/install.sh" && \
        sh "${tmpdir}/install.sh" -y -b "${HOME}/.local/bin"; then
        export PATH="${HOME}/.local/bin:$PATH"
        if have starship; then
            log_info "starship installed at ${HOME}/.local/bin/starship"
            exit 0
        fi
    fi
    log_warn "starship: install failed; shells will skip prompt initialization"
    exit 0
)

install_tree_sitter() (
    set -Eeuo pipefail
    if have tree-sitter && tree-sitter --version >/dev/null 2>&1; then
        log_info "tree-sitter already installed: $(tree-sitter --version)"
        exit 0
    fi

    if [[ -n "${TERMUX_VERSION:-}" ]]; then
        if have pkg && pkg install -y tree-sitter; then
            log_info "tree-sitter installed via pkg"
            exit 0
        fi
        log_warn "tree-sitter: pkg install failed; skipping"
        exit 0
    fi

    local os arch asset_os asset_arch pin_tag="v0.25.10" tag="" resp attempt url tmpdir
    os="$(uname -s)"
    arch="$(uname -m)"
    case "${os}-${arch}" in
        Linux-x86_64|Linux-amd64)   asset_os="linux"; asset_arch="x64" ;;
        Linux-aarch64|Linux-arm64)  asset_os="linux"; asset_arch="arm64" ;;
        Darwin-arm64)               asset_os="macos"; asset_arch="arm64" ;;
        Darwin-x86_64|Darwin-amd64) asset_os="macos"; asset_arch="x64" ;;
        *)
            log_warn "tree-sitter: unsupported platform ${os}-${arch}; skipping"
            exit 0
            ;;
    esac

    needs_pin() {
        [[ "$(uname -s)" == "Linux" ]] || return 1
        local ver
        ver=$(ldd --version 2>/dev/null | head -n 1 | grep -oE '[0-9]+\.[0-9]+' | head -n 1)
        [[ -n "$ver" ]] || return 1
        [[ "$(printf '%s\n%s\n' "$ver" "2.39" | sort -V | head -n 1)" != "2.39" ]]
    }

    if needs_pin; then
        log_info "tree-sitter: glibc < 2.39 detected; pinning to ${pin_tag}"
        tag="$pin_tag"
    else
        for attempt in 1 2 3; do
            tag=""
            if resp=$(curl -fsS --max-time 60 \
                https://api.github.com/repos/tree-sitter/tree-sitter/releases/latest 2>/dev/null); then
                tag=$(printf '%s\n' "$resp" \
                    | sed -nE 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' \
                    | head -n 1)
                if [[ "$tag" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+ ]]; then
                    break
                fi
                log_warn "tree-sitter: unexpected release tag '${tag}' from API; retrying"
            else
                log_warn "tree-sitter: API attempt ${attempt} failed; retrying"
            fi
            [[ "$attempt" -lt 3 ]] && sleep 2
        done
        [[ -n "$tag" ]] || tag="$pin_tag"
    fi

    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    install_tag() {
        local selected="$1"
        local asset="tree-sitter-${asset_os}-${asset_arch}.gz"
        local staged=""
        url="https://github.com/tree-sitter/tree-sitter/releases/download/${selected}/${asset}"
        log_info "Downloading tree-sitter ${selected} (${asset})..."
        if ! curl -fsS --max-time 60 -L "$url" -o "${tmpdir}/tree-sitter.gz"; then
            return 1
        fi
        mkdir -p "${HOME}/.local/bin"
        staged=$(mktemp "${HOME}/.local/bin/.tree-sitter.XXXXXX")
        if have gunzip; then
            gunzip -c "${tmpdir}/tree-sitter.gz" > "$staged" || { rm -f "$staged"; return 1; }
        elif have python3; then
            python3 -c 'import gzip,shutil,sys; shutil.copyfileobj(gzip.open(sys.argv[1], "rb"), open(sys.argv[2], "wb"))' \
                "${tmpdir}/tree-sitter.gz" "$staged" || { rm -f "$staged"; return 1; }
        else
            rm -f "$staged"
            return 1
        fi
        chmod +x "$staged"
        if ! "$staged" --version >/dev/null 2>&1; then
            rm -f "$staged"
            return 1
        fi
        if ! mv -f "$staged" "${HOME}/.local/bin/tree-sitter"; then
            rm -f "$staged"
            return 1
        fi
    }

    if install_tag "$tag"; then
        log_info "tree-sitter installed at ${HOME}/.local/bin/tree-sitter"
        exit 0
    fi
    if [[ "$tag" != "$pin_tag" ]] && install_tag "$pin_tag"; then
        log_info "tree-sitter installed at ${HOME}/.local/bin/tree-sitter (pinned fallback)"
        exit 0
    fi
    if have npm; then
        log_info "tree-sitter: GitHub download failed; falling back to npm..."
        if npm install -g tree-sitter-cli; then
            log_info "tree-sitter installed via npm"
            exit 0
        fi
    fi
    log_warn "tree-sitter: download failed and npm unavailable; skipping"
    exit 0
)

install_pkg_manager() (
    local package="$1" bin
    bin="$(binary_for_package "$package")"
    if have "$bin"; then
        log_info "${package} already installed"
        exit 0
    fi

    if have apt-get; then
        sudo apt-get install -y "$package"
    elif have dnf; then
        sudo dnf install -y "$package"
    elif have pacman; then
        sudo pacman -S --noconfirm --needed "$package"
    elif have brew; then
        brew install "$package"
    elif have pkg; then
        pkg install -y "$package"
    else
        log_warn "${package}: no supported package manager found; skipping"
        exit 0
    fi

    if have "$bin"; then
        log_info "${package} installed"
    else
        log_warn "${package}: install command finished but ${bin} is not on PATH"
    fi
    exit 0
)

install_git_clone() (
    local package="$1" url="$2" target parent tmpdir
    target="${HOME}/.local/share/${package}"
    if [[ -d "${target}/.git" ]]; then
        log_info "${package} already cloned at ${target}; skipping"
        exit 0
    fi
    if [[ -e "$target" ]]; then
        log_warn "${target} exists but is not a git repository; skipping"
        exit 0
    fi
    if [[ -z "$url" ]]; then
        log_warn "${package}: git-clone type requires a url; skipping"
        exit 0
    fi

    parent=$(dirname "$target")
    mkdir -p "$parent"
    tmpdir=$(mktemp -d "${parent}/.${package}.XXXXXX")
    trap 'rm -rf "$tmpdir"' EXIT
    log_info "Cloning ${package} from ${url}..."
    if git clone --depth 1 "$url" "$tmpdir"; then
        mv "$tmpdir" "$target"
        trap - EXIT
        log_info "${package} cloned at ${target}"
    else
        log_warn "${package}: git clone failed; skipping"
    fi
    exit 0
)

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

install_package() {
    local package="$1" type="$2" version="${3:-latest}" url="${4:-}"
    if [[ -z "$package" || -z "$type" ]]; then
        log_warn "install_package requires a package name and type"
        return 1
    fi

    if package_installed "$package" "$type"; then
        log_info "${package} already installed; skipping"
        return 0
    fi

    log_info "Installing ${package} (type: ${type}, version: ${version})..."
    case "$type" in
        standalone-binary)
            case "$package" in
                ripgrep)                 install_ripgrep ;;
                starship)                install_starship ;;
                tree-sitter-cli|tree-sitter) install_tree_sitter ;;
                *)
                    log_warn "no standalone-binary installer for '${package}'; skipping"
                    return 1
                    ;;
            esac
            ;;
        pkg-manager)
            install_pkg_manager "$package"
            ;;
        git-clone)
            install_git_clone "$package" "$url"
            ;;
        *)
            log_warn "unknown package type '${type}' for '${package}'; skipping"
            return 1
            ;;
    esac
}

parse_manifest() {
    local manifest_path="$1"
    if [[ ! -f "$manifest_path" ]]; then
        log_warn "manifest not found at ${manifest_path}"
        return 1
    fi

    awk '
    BEGIN { pkg=""; type=""; version="latest"; url="" }
    /^[a-zA-Z]/ {
        if (pkg != "") print pkg "|" type "|" version "|" url
        pkg = $1
        sub(/:$/, "", pkg)
        type = ""; version = "latest"; url = ""
        next
    }
    /^[[:space:]]+type:/    { type = $2; next }
    /^[[:space:]]+version:/ { version = $2; next }
    /^[[:space:]]+url:/ {
        sub(/^[[:space:]]+url:[[:space:]]*/, "")
        gsub(/^"|"$/, "")
        url = $0
        next
    }
    END { if (pkg != "") print pkg "|" type "|" version "|" url }
    ' "$manifest_path"
}

process_manifest() {
    local manifest_path="$1" filter="${2:-}"
    if [[ ! -f "$manifest_path" ]]; then
        log_warn "manifest not found at ${manifest_path}; nothing to do"
        return 1
    fi

    log_info "[MANIFEST HANDLER] ${manifest_path}"
    local has_failures=0 package_count=0 pkg_name pkg_type pkg_version pkg_url
    while IFS='|' read -r pkg_name pkg_type pkg_version pkg_url; do
        [[ -z "$pkg_name" || "$pkg_name" == \#* || "$pkg_name" =~ ^-+$ ]] && continue
        if [[ -n "$filter" && "$pkg_name" != "$filter" ]]; then
            continue
        fi
        package_count=$((package_count + 1))
        if ! install_package "$pkg_name" "$pkg_type" "$pkg_version" "$pkg_url"; then
            has_failures=1
        fi
    done < <(parse_manifest "$manifest_path")
    log_info "[MANIFEST HANDLER] processed ${package_count} package(s)"

    [[ "$has_failures" -eq 0 ]]
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -Eeuo pipefail
    if [[ -z "${1:-}" ]]; then
        echo "Usage: $0 <manifest/dependencies.yaml> [package-name]" >&2
        exit 1
    fi
    process_manifest "$1" "${2:-}"
fi
