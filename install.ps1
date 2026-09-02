# Bootstrap script for Windows (PowerShell).
# Mirrors install.sh: ensure chezmoi, then pull the dotfiles and apply.

$ErrorActionPreference = 'Stop'

Write-Host @"

▄▄▄▄   ▄▄▄  ▄▄ ▄▄ ▄▄    ▄▄ ▄▄  ▄▄▄▄ ████▄ ██▀██ ██▀██ ██▄██ ██    ██ ██ ██ ▄▄  ▄▄██ 
████▀ ██▀██  ▀█▀  ██▄▄▄ ▀███▀ ▀███▀ ▄▄▄█▀ 
                                          
  installing dotfiles...
"@

function Install-Starship {
    if (Get-Command starship -ErrorAction SilentlyContinue) {
        Write-Host ">>> starship already installed"
        return
    }

    Write-Host ">>> starship not found; installing..."

    # Strategy 1: winget (preferred on Windows)
    try {
        Write-Host ">>> trying winget..."
        winget install --id Starship.Starship --exact --accept-source-agreements --accept-package-agreements 2>$null
        if (Get-Command starship -ErrorAction SilentlyContinue) { return }
    } catch { }

    # Strategy 2: scoop
    try {
        Write-Host ">>> trying scoop..."
        scoop install starship 2>$null
        if (Get-Command starship -ErrorAction SilentlyContinue) { return }
    } catch { }

    # Strategy 3: official installer
    Write-Host ">>> trying official installer..."
    $binDir = "$env:USERPROFILE\.local\bin"
    if (-not (Test-Path $binDir)) { New-Item -ItemType Directory -Path $binDir -Force | Out-Null }
    $installer = "$env:TEMP\starship-install.ps1"
    Invoke-WebRequest -Uri "https://starship.rs/install.ps1" -OutFile $installer
    & $installer -BinDir $binDir -Yes
    Remove-Item $installer -Force

    if (-not (Get-Command starship -ErrorAction SilentlyContinue)) {
        throw "starship installation failed"
    }
}

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

Install-Starship
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
