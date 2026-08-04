# Bootstrap script for Windows (PowerShell).
# Mirrors install.sh: ensure chezmoi, then pull the dotfiles and apply.

$ErrorActionPreference = 'Stop'

Write-Host @"

    _____  _____  __ __  ____   __ __  _____  _____
   |  _  \/  _  \/  |  \/  _/  /  |  \/   __\/  _  \
   |  |  ||  _  |\  |  /|  |---|  |  ||  |_ |>-<_  <
   |_____/\__|__/ \___/ \_____/\_____/\_____/\_____/

  installing dotfiles...
"@

function Install-Chezmoi {
    if (Get-Command chezmoi -ErrorAction SilentlyContinue) {
        Write-Host "chezmoi already installed"
        return
    }
    try {
        Write-Host "installing chezmoi via winget..."
        winget install --id twpayne.chezmoi --exact --accept-source-agreements --accept-package-agreements
    } catch {
        Write-Host "winget failed, using official installer..."
        Invoke-Expression (Invoke-RestMethod https://get.chezmoi.io/ps1)
    }
    if (-not (Get-Command chezmoi -ErrorAction SilentlyContinue)) {
        throw "chezmoi installation failed"
    }
}

Install-Chezmoi

$localRepo = $false
if ($PSCommandPath) {
    $scriptDir = Split-Path -Parent $PSCommandPath
    if ($PWD.Path -eq $scriptDir) { $localRepo = $true }
}

if ($localRepo) {
    Write-Host "applying dotfiles from local repo..."
    chezmoi apply
} else {
    Write-Host "pulling dotfiles from GitHub..."
    chezmoi init --apply davlug3/dotfiles
}

Write-Host ""
Write-Host "done! dotfiles applied."
