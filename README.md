# dotfiles

My personal config files using [chezmoi](https://chezmoi.io). I use this repo for automating my setup on a new machine.

## Installation

### Option 1 — One-liner, no need to clone

```bash
curl -fsSL https://raw.githubusercontent.com/davlug3/dotfiles/main/install.sh | bash
```

The script will install chezmoi if not yet installed, then it will run `chezmoi init --apply` to pull the dotfiles from GitHub.

### Option 2 — Using chezmoi directly

```bash
sh -c "$(curl -fsLS https://chezmoi.io/get)" -- init --apply davlug3/dotfiles
```

### Option 3 — Clone it yourself

```bash
git clone https://github.com/davlug3/dotfiles.git
cd dotfiles
./install.sh
```

## Usage

```bash
chezmoi add ~/.someconfig    # add a new file
chezmoi edit ~/.someconfig   # edit a tracked file
chezmoi diff                 # see what will change before applying
chezmoi apply                # apply changes to $HOME
chezmoi update               # pull latest from GitHub and reapply
```

## Features

### Templates

Files with `.tmpl` extension can use chezmoi template variables for OS and hostname detection:

```bash
chezmoi add --template ~/.bashrc
```

Built-in variables available:

| Variable | Example | Description |
|----------|---------|-------------|
| `.chezmoi.os` | `linux`, `darwin` | Operating system |
| `.chezmoi.hostname` | `my-pc` | Machine hostname |
| `.chezmoi.arch` | `amd64`, `arm64` | CPU architecture |
| `.chezmoi.username` | `dave` | Current user |

Example — OS-specific aliases:

```
{{ if eq .chezmoi.os "darwin" -}}
alias brewup="brew update && brew upgrade && brew cleanup"
{{ end -}}
```

### Run-once scripts

Scripts prefixed with `run_once_` execute automatically on first `chezmoi apply`. Currently runs:

- **vim-plug** — installs plugin manager and runs `PlugInstall`

### Starship prompt

A minimal [starship](https://starship.rs) config is included at `~/.config/starship.toml`. Enable it:

```bash
# Install starship
curl -sS https://starship.rs/install.sh | sh

# Add to ~/.bashrc
eval "$(starship init bash)"
```

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

Inside the file, use `{{ promptStringOnce . "key" "Enter your token" }}` — chezmoi will ask once and store the answer in `~/.config/chezmoi/chezmoi.toml`.

## What's included

- **bash** — .bashrc (template with OS detection), .bash_profile, .bash_aliases, .bash_logout
- **git** — .gitconfig
- **tmux** — with TPM and dracula theme
- **vim** — with vim-plug, nerdtree, coc.nvim, and more
- **prompt** — starship config

## Notes

- Vim config is still messy, will fix it when I have time
