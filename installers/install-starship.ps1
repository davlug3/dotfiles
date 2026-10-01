# install-starship.ps1 — pre-scripted starship installer, invocable any time.
# Managed by chezmoi: installers/install-starship.ps1 -> ~/installers/install-starship.ps1
# Invoke any time with: & "$HOME/installers/install-starship.ps1"
$ErrorActionPreference = 'Stop'

if (Get-Command starship -ErrorAction SilentlyContinue) {
    Write-Host "starship already installed: $(starship --version | Select-Object -First 1)"
    exit 0
}

Write-Host "starship not found; installing..."

# Strategy 1: winget (preferred on Windows)
try {
    Write-Host "trying winget..."
    winget install --id Starship.Starship --exact --accept-source-agreements --accept-package-agreements 2>$null
    if (Get-Command starship -ErrorAction SilentlyContinue) { exit 0 }
} catch { }

# Strategy 2: scoop
try {
    Write-Host "trying scoop..."
    scoop install starship 2>$null
    if (Get-Command starship -ErrorAction SilentlyContinue) { exit 0 }
} catch { }

# Strategy 3: official installer
Write-Host "trying official installer..."
$binDir = "$env:USERPROFILE\.local\bin"
if (-not (Test-Path $binDir)) { New-Item -ItemType Directory -Path $binDir -Force | Out-Null }
$installer = "$env:TEMP\starship-install.ps1"
Invoke-WebRequest -Uri "https://starship.rs/install.ps1" -OutFile $installer
& $installer -BinDir $binDir -Yes
Remove-Item $installer -Force

if (-not (Get-Command starship -ErrorAction SilentlyContinue)) {
    throw "starship installation failed"
}
Write-Host "starship installed successfully"
