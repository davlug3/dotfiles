# install-nvim.ps1 — pre-scripted neovim installer, invocable any time.
# Managed by chezmoi: installers/install-nvim.ps1 -> ~/installers/install-nvim.ps1
# Invoke any time with: & "$HOME/installers/install-nvim.ps1"
$ErrorActionPreference = 'Stop'

if (Get-Command nvim -ErrorAction SilentlyContinue) {
    Write-Host "neovim already installed: $(nvim --version | Select-Object -First 1)"
    exit 0
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget not found; install App Installer from the Microsoft Store, then re-run."
    exit 1
}

winget install --id Neovim.Neovim --exact --accept-source-agreements --accept-package-agreements
Write-Host "neovim installed via winget"
