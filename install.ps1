# Bootstrap script for Windows (PowerShell).
# Mirrors install.sh: ensure chezmoi, then pull the dotfiles and apply.

$ErrorActionPreference = 'Stop'

Write-Host @"

▄▄▄▄   ▄▄▄  ▄▄ ▄▄ ▄▄    ▄▄ ▄▄  ▄▄▄▄ ████▄ ██▀██ ██▀██ ██▄██ ██    ██ ██ ██ ▄▄  ▄▄██ 
████▀ ██▀██  ▀█▀  ██▄▄▄ ▀███▀ ▀███▀ ▄▄▄█▀ 
                                          
  installing dotfiles...
"@

$DOTFILES_REF = if ($env:DOTFILES_REF) { $env:DOTFILES_REF } else { "main" }
$REPO_RAW = "https://raw.githubusercontent.com/davlug3/dotfiles/$DOTFILES_REF/installers"

function Update-SessionPath {
    $machine = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    if ($machine -and $user) { $env:Path = "$machine;$user" }
    elseif ($machine) { $env:Path = $machine }
    elseif ($user) { $env:Path = "$env:Path;$user" }
}

# Single source of truth for package installs lives in installers/.
# Runs installers/<name>.ps1 from the local clone when present,
# otherwise fetches it from GitHub (remote bootstrap mode).
function Invoke-PackageInstaller {
    param([string]$Name)
    if ($PSScriptRoot) {
        $local = Join-Path (Join-Path $PSScriptRoot "installers") "$Name.ps1"
        if (Test-Path $local) {
            & $local
            return
        }
    }
    Write-Host "fetching $Name installer from GitHub (ref $DOTFILES_REF)..."
    $script = Invoke-RestMethod -UseBasicParsing "$REPO_RAW/$Name.ps1"
    # Run fetched script via temp file so $ErrorActionPreference=Stop applies
    $tempDir = $env:TEMP
    if (-not $tempDir) { $tempDir = $env:TMP }
    if (-not $tempDir) { $tempDir = [System.IO.Path]::GetTempPath() }
    $tmp = Join-Path $tempDir "chezmoi-$Name.ps1"
    Set-Content -Path $tmp -Value $script
    try {
        & $tmp
    } finally {
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
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
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        try {
            Write-Host "installing chezmoi via winget..."
            winget install --id twpayne.chezmoi --exact --source winget --accept-source-agreements --accept-package-agreements
            Update-SessionPath
            if (Get-Command chezmoi -ErrorAction SilentlyContinue) { return }
            Write-Warning "winget did not leave chezmoi on PATH (exit=$LASTEXITCODE), trying official installer..."
        } catch {
            Write-Warning "winget failed: $($_.Exception.Message), trying official installer..."
        }
    }
    Write-Host "installing chezmoi via official installer..."
    Invoke-Expression (Invoke-RestMethod -UseBasicParsing https://get.chezmoi.io/ps1)
    Update-SessionPath
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
