#!/bin/bash

# handlers/package_handler.sh
# Generic Package Handler implementation
# This module centralizes installation logic read from manifest/dependencies.yaml.
#
# USAGE: source $(basename $0) <path/to/manifest/dependencies.yaml>
#        Then call: process_manifest "$MANIFEST_PATH"

set -Eeuo pipefail

# ============================================================================
# install_package <name> <type> <version> [url]
# Installs a single package based on its type.
# ============================================================================
install_package() {
    local package_name="$1"
    local package_type="$2"
    local package_version="${3:-latest}"
    local package_url="${4:-}"

    if [[ -z "$package_name" || -z "$package_type" ]]; then
        echo "ERROR: install_package requires both a package name and type." >&2
        return 1
    fi

    echo -e "\n--- [HANDLER] Attempting installation for '$package_name' (Type: $package_type, Version: $package_version) ---"

    case "$package_type" in
        standalone-binary)
            echo "INFO: Standalone binary setup for $package_name..."
            case "$package_name" in
                ripgrep)
                    echo "Installing ripgrep to ~/.local/bin..."
                    mkdir -p "${HOME}/.local/bin"
                    # In production, this would download and extract the actual binary.
                    # For now, simulate success.
                    touch "${HOME}/.local/bin/rg"
                    echo "SUCCESS: ripgrep simulated installed."
                    ;;
                starship)
                    echo "Installing starship via official installer..."
                    mkdir -p "${HOME}/.local/bin"
                    # In production: curl -sS https://starship.rs/install.sh | sh -s -- -y -b "${HOME}/.local/bin"
                    touch "${HOME}/.local/bin/starship"
                    echo "SUCCESS: starship simulated installed."
                    ;;
                *)
                    echo "WARNING: Standalone binary handler for '$package_name' is not implemented yet. Skipping."
                    return 1
                    ;;
            esac
            ;;

        pkg-manager)
            echo "INFO: System package manager setup for $package_name..."
            # Detect available package manager and install
            if command -v apt-get &>/dev/null; then
                echo "Using apt-get to install $package_name..."
                # sudo apt-get update && sudo apt-get install -y "$package_name"
                echo "SUCCESS: $package_name installed via apt-get (simulated)."
            elif command -v dnf &>/dev/null; then
                echo "Using dnf to install $package_name..."
                # sudo dnf install -y "$package_name"
                echo "SUCCESS: $package_name installed via dnf (simulated)."
            elif command -v pacman &>/dev/null; then
                echo "Using pacman to install $package_name..."
                # sudo pacman -S --noconfirm --needed "$package_name"
                echo "SUCCESS: $package_name installed via pacman (simulated)."
            elif command -v brew &>/dev/null; then
                echo "Using brew to install $package_name..."
                # brew install "$package_name"
                echo "SUCCESS: $package_name installed via brew (simulated)."
            elif command -v pkg &>/dev/null; then
                echo "Using pkg (Termux) to install $package_name..."
                # pkg install -y "$package_name"
                echo "SUCCESS: $package_name installed via pkg (simulated)."
            else
                echo "ERROR: No supported package manager found for $package_name." >&2
                return 1
            fi
            ;;

        git-clone)
            echo "INFO: Git clone setup for $package_name..."
            if [[ -z "$package_url" ]]; then
                echo "ERROR: git-clone type requires a 'url' field for $package_name." >&2
                return 1
            fi
            echo "Cloning $package_name from $package_url..."
            # git clone "$package_url" "${HOME}/.local/share/$package_name"
            echo "SUCCESS: $package_name cloned (simulated)."
            ;;

        *)
            echo "ERROR: Unknown package type '$package_type' specified for $package_name." >&2
            return 1
            ;;
    esac
    echo -e "--- [HANDLER] Finished setup attempt for $package_name ---"
    return 0
}


# ============================================================================
# parse_manifest <manifest_path>
# Parses the YAML manifest and outputs lines of "name|type|version|url"
# ============================================================================
parse_manifest() {
    local manifest_path="$1"
    if [[ ! -f "$manifest_path" ]]; then
        echo "CRITICAL ERROR: Manifest file not found at $manifest_path." >&2
        return 1
    fi

    # Use awk to parse the simple YAML structure:
    # - Top-level keys (no leading whitespace) are package names
    # - Indented keys under each package are its fields
    awk '
    BEGIN { pkg=""; type=""; version="latest"; url="" }
    /^[a-zA-Z]/ {
        # New package block — flush previous
        if (pkg != "") {
            print pkg "|" type "|" version "|" url
        }
        pkg = $1
        sub(/:$/, "", pkg)
        type = ""; version = "latest"; url = ""
        next
    }
    /^[[:space:]]+type:/ {
        type = $2
        next
    }
    /^[[:space:]]+version:/ {
        version = $2
        next
    }
    /^[[:space:]]+url:/ {
        # Capture everything after "url:" (may contain spaces/quotes)
        sub(/^[[:space:]]+url:[[:space:]]*/, "")
        gsub(/^"|"$/, "")
        url = $0
        next
    }
    END {
        if (pkg != "") {
            print pkg "|" type "|" version "|" url
        }
    }
    ' "$manifest_path"
}


# ============================================================================
# process_manifest <manifest_path>
# Reads the manifest, parses all dependencies, and installs each one.
# ============================================================================
process_manifest() {
    local manifest_path="$1"
    if [[ ! -f "$manifest_path" ]]; then
        echo "CRITICAL ERROR: Manifest file not found at $manifest_path. Cannot proceed with installation." >&2
        return 1
    fi

    echo -e "\n[MANIFEST HANDLER] Parsing manifest file: $manifest_path..."
    echo "--- Starting dependency graph traversal and execution... ---"

    local has_failures=0
    local package_count=0

    while IFS='|' read -r pkg_name pkg_type pkg_version pkg_url; do
        # Skip empty lines
        [[ -z "$pkg_name" ]] && continue

        # Skip comment-only or separator lines
        [[ "$pkg_name" =~ ^# ]] && continue
        [[ "$pkg_name" =~ ^-+$ ]] && continue

        package_count=$((package_count + 1))

        if ! install_package "$pkg_name" "$pkg_type" "$pkg_version" "$pkg_url"; then
            has_failures=1
        fi
    done < <(parse_manifest "$manifest_path")

    echo -e "\n--- [MANIFEST HANDLER] Processed $package_count packages. ---"

    if [[ $has_failures -ne 0 ]]; then
        echo "WARNING: One or more packages failed to install. Review logs above." >&2
        return 1
    fi

    return 0
}

# ============================================================================
# Guard: Only run process_manifest if this script is executed directly
# (not sourced). When sourced, the caller invokes process_manifest explicitly.
# ============================================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ -z "${1:-}" ]]; then
        echo "Usage: $0 <path/to/manifest/dependencies.yaml>" >&2
        exit 1
    fi
    process_manifest "$1"
fi