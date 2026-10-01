# Bootstrap script for Windows (PowerShell).
# Mirrors install.sh: ensure chezmoi, then pull the dotfiles and apply.

$ErrorActionPreference = 'Stop'

Write-Host @"

▄▄▄▄   ▄▄▄  ▄▄ ▄▄ ▄▄    ▄▄ ▄▄  ▄▄▄▄ ████▄ ██▀██ ██▀██ ██▄██ ██    ██ ██ ██ ▄▄  ▄▄██ 
████▀ ██▀██  ▀█▀  ██▄▄▄ ▀███▀ ▀███▀ ▄▄▄█▀ 
                                          
  installing dotfiles...
"@

$REPO_RAW = "https://raw.githubusercontent.com/davlug3/dotfiles/main/installers"

# Single source of truth for package installs lives in installers/.
# Runs installers/<name>.ps1 from the local clone when present,
# otherwise fetches it from GitHub (remote bootstrap mode).
function Invoke-PackageInstaller {
    param([string]$Name)
    $local = Join-Path (Join-Path $PSScriptRoot "installers") "$Name.ps1"
    if (($PSScriptRoot) -and (Test-Path $local)) {
        & $local
    } else {
        Write-Host "fetching $Name installer from GitHub..."
        $script = Invoke-RestMethod "$REPO_RAW/$Name.ps1"
        # Run fetched script via temp file so $ErrorActionPreference=Stop applies
        $tmp = Join-Path $env:TEMP "chezmoi-$Name.ps1"
        Set-Content -Path $tmp -Value $script
        & $tmp
        Remove-Item $tmp -Force
    }
}

function Install-Starship {
    Write-Host ">>> ensuring starship..."
    Invoke-PackageInstaller "install-starship"
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
