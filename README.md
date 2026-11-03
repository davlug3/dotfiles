# dotfiles

My personal config files using [chezmoi](https://chezmoi.io). I use this repo to automate my setup on a new machine.

---

## System Architecture (Manifest-Driven)

This repository uses a manifest-driven architecture for dependency management. All required software packages are declared in `manifest/dependencies.yaml`.

The process flow:

1. **Bootstrap:** Run `install.sh` (Linux/macOS) or `install.ps1` (Windows).
2. **Discovery:** The installer resolves and sources `handlers/package_handler.sh` (Unix) or `handlers/package_handler.ps1` (Windows).
3. **Execution:** The handler reads `manifest/dependencies.yaml`, parses each entry, and dispatches to the appropriate installation logic based on the declared `type`.

Adding a new dependency requires an entry in the manifest. No core scripts need modification if the handler supports the package's type.

---

## Installation

Pick whichever method you prefer.

### Option A — This repo's installer

```bash
curl -fsSL https://raw.githubusercontent.com/davlug3/dotfiles/main/install.sh | bash
```

Installs chezmoi if missing, runs the dependency handler, and applies all dotfiles via `chezmoi init --apply`.

### Option B — Official chezmoi installer

```bash
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply davlug3/dotfiles
```

Installs chezmoi via the official script and runs `init --apply`. The `-b "$HOME/.local/bin"` flag is required: the default installer puts chezmoi in a relative `bin/` directory that isn't on your `PATH`. Your dotfiles already prepend `$HOME/.local/bin` to `PATH`.

### Option C — Clone it yourself

```bash
git clone https://github.com/davlug3/dotfiles.git
cd dotfiles
./install.sh
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/davlug3/dotfiles/main/install.ps1 | iex
```

Installs chezmoi (winget, falling back to the official installer) and runs `chezmoi apply`. On Windows it installs:

- PowerShell profiles for both PowerShell 7 (`Documents\PowerShell`) and Windows PowerShell 5.1 (`Documents\WindowsPowerShell`), each inits starship
- vim (`.vimrc` + vim-plug, plugins via `PlugInstall`)
- nvim (config at `~/.config/nvim`, linked to `%LOCALAPPDATA%\nvim` via a junction)

Note: nvim-treesitter parsers install automatically on first launch (needs a `cc`/clang compiler).

On Linux/macOS, ripgrep (`rg`) is installed to `~/.local/bin` on first run for fast fuzzy finding with Telescope. On Termux and Windows (winget), ripgrep comes from the platform package manager. If ripgrep is unavailable, Telescope falls back to native `grep`.

---

## Usage

```bash
chezmoi add ~/.someconfig    # track a new file
chezmoi edit ~/.someconfig   # edit a tracked file
chezmoi diff                 # review changes before applying
chezmoi apply                # apply changes to $HOME
chezmoi update               # pull latest and reapply
```

---

## Key Features

### Templates (`.tmpl`)

Files with `.tmpl` extension use chezmoi's templating engine with OS and hostname detection:

```bash
chezmoi add --template ~/.bashrc
```

Built-in variables:

| Variable | Example | Description |
|----------|---------|-------------|
| `.chezmoi.os` | `linux`, `darwin` | Operating system |
| `.chezmoi.hostname` | `my-pc` | Machine hostname |
| `.chezmoi.arch` | `amd64`, `arm64` | CPU architecture |
| `.chezmoi.username` | `dave` | Current user |

OS-specific aliases example:

```
{{ if eq .chezmoi.os "darwin" -}}
alias brewup="brew update && brew upgrade && brew cleanup"
{{ end -}}
```

### Editing templates in Neovim

Neovim uses [`dpezto/chezmoi-template.nvim`](https://github.com/dpezto/chezmoi-template.nvim) on the real source files (no `chezmoi edit` temp buffers):

- `.tmpl` files are `gotmpl` buffers with the deployed filetype's syntax injected (e.g. shell inside `dot_bashrc.tmpl`). When no treesitter parser exists for the deployed type (`tmux`, `gitconfig`, etc.), the usual Vim syntax file is used instead.
- Saving a managed source file runs `chezmoi apply` for that target.
- `:Chezmoi preview` renders the template in a split and marks the diff against the deployed file.
- In a source buffer, `\C` opens a which-key group: `p` preview, `a` apply, `t` open target, `s` open source, `e` edit target, `f` pick. `\fC` opens the source picker (Telescope).
- `conform.nvim` formats templates as their target language on save, using `stylua`, `shfmt`, and `taplo` (installed by Mason).

---

## Dependency Management

All required software dependencies are declared in `manifest/dependencies.yaml`.

### Manifest Format

Each entry is a YAML mapping:

| Field | Required | Description |
|-------|----------|-------------|
| `type` | Yes | Installation method: `standalone-binary`, `pkg-manager`, or `git-clone` |
| `version` | No | Version to install (`latest` by default) |
| `description` | No | Human-readable description |
| `url` | For `git-clone` | Source URL for cloning |

### Package Types

| Type | Description | Example |
|------|-------------|---------|
| `standalone-binary` | Download and extract a prebuilt binary | ripgrep, starship |
| `pkg-manager` | Install via system package manager (apt, dnf, brew, etc.) | neovim |
| `git-clone` | Clone from a Git repository | nvim-treesitter |

### How It Works

1. The bootstrap script resolves the handler path (repo source first, then deployed path).
2. It sources `handlers/package_handler.sh` (Unix) or `handlers/package_handler.ps1` (Windows).
3. It calls `process_manifest()` with the path to `manifest/dependencies.yaml`.
4. The handler parses the manifest and dispatches each entry to `install_package()` based on its type.
5. Each package is installed using platform-appropriate logic.

### Package Installer Scripts (`installers/`)

The scripts in `installers/` are thin wrappers. They contain no installation logic themselves, only path resolution, handler sourcing, and a call to `process_manifest()`.

All installers are idempotent (exit 0 when already installed). Invoke any one any time:

```bash
~/installers/install-nvim.sh
~/installers/install-lilypond.sh
~/installers/install-starship.sh
```

```powershell
& "$HOME/installers/install-nvim.ps1"
```

| Package | First-apply prompt | Default |
|---------|-------------------|---------|
| neovim | `Install neovim?` | Yes |
| lilypond | `Install lilypond?` | No |
| starship | none (always installed, shell rc depends on it) | — |

### Run-once Scripts

Scripts prefixed with `run_once_` execute automatically on first `chezmoi apply`. They now call `process_manifest()` internally.

Currently runs:

- **vim-plug** — installs plugin manager and runs `PlugInstall`
- **JetBrains Mono Nerd Font** — installs the font for Unix systems (desktop font cache on Linux/macOS, terminal font via `~/.termux/font.ttf` on Termux)
- **neovim** — gated on the `Install neovim?` prompt; delegates to `~/installers/install-nvim.sh`
- **lilypond** — gated on the `Install lilypond?` prompt; delegates to `~/installers/install-lilypond.sh`
- **ripgrep** — installs `rg` for fast Telescope live_grep (prebuilt binary on Linux/macOS, `pkg` on Termux, winget on Windows); Telescope falls back to native `grep` if rg is missing

### Starship prompt

A minimal [starship](https://starship.rs) config is included at `~/.config/starship.toml`. To enable it:

```bash
# Install starship (same script the bootstrap uses)
~/installers/install-starship.sh

# Add to ~/.bashrc
eval "$(starship init bash)"
```

---

## What's Included

- bash: `.bashrc` (template with OS detection), `.bash_profile`, `.bash_aliases`, `.bash_logout`
- git: `.gitconfig`
- tmux: with TPM and dracula theme
- vim: with vim-plug, nerdtree, coc.nvim, and more
- prompt: starship config
- nvim: config at `~/.config/nvim`, linked to `%LOCALAPPDATA%\nvim` via a junction (Windows)

### Keymap discovery (Neovim)

Neovim ships with [`folke/which-key.nvim`](https://github.com/folke/which-key.nvim) for interactive keymap discovery. Press `<Space>` (your leader) and a popup lists every mapping starting with it. Keep typing to drill in. Browse everything at once with `<Leader>` `?`, or inspect a specific mode from the command line with `:nmap`, `:map <Leader>`, or `:filter /pattern/ nmap`.

---

## Secrets

This repo is public, so nothing sensitive goes in here.

### Option 1 — Exclude the file entirely

```bash
echo "dot_ssh/private_id_rsa" >> .gitignore
```

Then copy the secret manually on each machine.

### Option 2 — Use a template with a prompt

```bash
chezmoi add --template ~/.config/some-token
```

Inside the file, use `{{ promptStringOnce . "key" "Enter your token" }}`. Chezmoi will ask once and store the answer in `~/.config/chezmoi/chezmoi.toml`.

### Guardrails

`.gitignore` blocks common secret filenames, and `hooks/pre-commit` runs `gitleaks protect --staged` on every commit. `run_after_set-git-hooks-path.sh.tmpl` points git at the tracked hooks automatically on each `chezmoi apply` (`core.hooksPath` can't be committed, so the script re-applies it instead). Manual equivalent, if ever needed:

```bash
git config core.hooksPath hooks
```

---

## Notes

- Vim config is still messy, will fix it when I have time
- The handler's `apt`, `pkg-manager`, and `git-clone` types are currently simulated (they print success but don't execute real commands). Full implementation will replace the `echo` stubs with actual `apt-get`, `git clone`, etc. commands.