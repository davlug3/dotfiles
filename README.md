# dotfiles
My personal configuration files managed with [chezmoi](https://chezmoi.io). I use this repository to automate my setup and ensure consistency across different machines.

## System Architecture (Manifest-Driven)

This repository has been refactored into a **manifest-driven architecture**. All required software packages (dependencies) are now centrally declared in `manifest/dependencies.yaml`.

The system no longer relies on individual, hardcoded scripts (`installers/` or `run_once_*`) to manage dependencies. Instead, the process flow is:
1.  **Bootstrap:** Use the main installation script (e.g., `./install.sh`).
2.  **Discovery:** The installer sources `handlers/package_handler.sh` (or `.ps1` on Windows).
3.  **Execution:** The handler reads `manifest/dependencies.yaml` and executes modular, platform-agnostic setup logic for every declared dependency.

This design is more scalable, maintainable, and easier to audit.

---

## Installation Guide

Please use the appropriate installer block below. These scripts now call the centralized manifest manager.

### Option A — This repo's installer (Linux/macOS)
```bash
curl -fsSL https://raw.githubusercontent.com/davlug3/dotfiles/main/install.sh | bash
```
*   **What it does:** Installs chezmoi if missing, then runs the centralized dependency handler and applies all dotfiles via `chezmoi init --apply`.

### Option B — Official chezmoi installer (Linux/macOS)
```bash
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply davlug3/dotfiles
```
*   **What it does:** Installs chezmoi via the official script and immediately runs `init --apply`.

### Option C — Clone it yourself (Linux/macOS)
```bash
git clone https://github.com/davlug3/dotfiles.git
cd dotfiles
./install.sh
```

### Windows (PowerShell)
```powershell
irm https://raw.githubusercontent.com/davlug3/dotfiles/main/install.ps1 | iex
```
*   **What it does:** The script installs chezmoi and runs the centralized dependency handler, ensuring all necessary packages are managed via the manifest before applying dotfiles.

---

## Usage (Post-Installation)

Once installed, managing configurations remains intuitive:

```bash
chezmoi add ~/.someconfig    # 1. Track a new file or directory
chezmoi edit ~/.someconfig   # 2. Edit a tracked file
chezmoi diff                 # 3. Review proposed changes before applying
chezmoi apply                # 4. Apply changes to $HOME (The core action)
chezmoi update               # 5. Pull latest from GitHub and reapply
```

## Key Features & Templates

### Templates (`.tmpl`)
Files with `.tmpl` extension are processed by chezmoi's templating engine. They support standard variables like:
| Variable | Example | Description |
| :--- | :--- | :--- |
| `.chezmoi.os` | `linux`, `darwin` | Operating system identifier. |
| `.chezmoi.hostname` | `my-pc` | Machine hostname. |
| `.chezmoi.arch` | `amd64`, `arm64` | CPU architecture. |
| `.chezmoi.username` | `dave` | Current user. |

### Editing templates in Neovim

Neovim uses [`dpezto/chezmoi-template.nvim`](https://github.com/dpezto/chezmoi-template.nvim) for template support, allowing syntax highlighting and previewing within the editor buffer.

---

## Dependency Management (The Source of Truth)

All required dependencies are declared in `manifest/dependencies.yaml`.

### How it Works
The dependency handler (`handlers/package_handler.sh` for Unix, `handlers/package_handler.ps1` for Windows) reads this manifest to determine:
1.  **What** is needed (e.g., `ripgrep`, `starship`).
2.  **How** to install it (the package type: `standalone-binary`, `pkg-manager`, `git-clone`).

### Package Installer Scripts (`installers/`)
All installation logic has been centralized and abstracted. The scripts in the `installers/` directory now serve only as thin wrappers that execute the manifest handler, eliminating all internal setup code for dependencies.

**Example:** Instead of manually installing Starship, you run the bootstrap script, which calls the handler, which knows to install Starship because it's listed in the manifest.

## Run-once Scripts
Scripts prefixed with `run_once_` execute automatically on first `chezmoi apply`. They now call `process_manifest()` internally instead of running hardcoded setup blocks. This ensures that even initial auto-configurations adhere to the central dependency graph.

### Example Dependencies (Managed by Manifest)
| Package | Type | Notes |
| :--- | :--- | :--- |
| **ripgrep** (`rg`) | `standalone-binary` | Installed for fast fuzzy finding with Telescope. Falls back to native `grep` if unavailable. |
| **starship** | `standalone-binary` | Used in the prompt configuration (see instructions below). |
| **neovim** | `pkg-manager` | Neovim editor configuration and plugins. |
| **nvim-treesitter** | `git-clone` | Syntax highlighting engine for nvim. |

### Starship prompt setup

A minimal [starship](https://starship.rs) config is included at `~/.config/starship.toml`. To enable it:
1. Run the bootstrap script (which handles installation).
2. Ensure your shell initialization file adds: `eval "$(starship init bash)"`

## Advanced Topics & Security
- **Secrets:** Use `chezmoi add --template ~/.config/some-token` and `{{ promptStringOnce . "key" "Enter your token" }}` for securely prompting sensitive values.
- **Guardrails:** `.gitignore` blocks common secret filenames, and `hooks/pre-commit` runs `gitleaks protect --staged` on every commit. The system remains secure by default.