# install-starship.ps1 — pre-scripted starship installer, invocable any time.
# Managed by chezmoi: installers/install-starship.ps1 -> ~/installers/install-starship.ps1
# Invoke any time with: & "$HOME/installers/install-starship.ps1"
# NOTE: uses `return` (not `exit`) so it is safe to invoke via `&` from a bootstrap script.
$ErrorActionPreference = 'Stop'

function Update-SessionPath {
    $machine = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    if ($machine -and $user) { $env:Path = "$machine;$user" }
    elseif ($machine) { $env:Path = $machine }
    elseif ($user) { $env:Path = "$env:Path;$user" }
}

if (Get-Command starship -ErrorAction SilentlyContinue) {
    Write-Host "starship already installed: $(starship --version | Select-Object -First 1)"
    return
}

Write-Host "starship not found; installing..."

# Strategy 1: winget (preferred on Windows)
# NOTE: --source winget avoids slow/failed msstore lookups (WinHttp 12002).
if (Get-Command winget -ErrorAction SilentlyContinue) {
    try {
        Write-Host "trying winget..."
        winget install --id Starship.Starship --exact --source winget --accept-source-agreements --accept-package-agreements
        Update-SessionPath
        if (Get-Command starship -ErrorAction SilentlyContinue) { return }
        Write-Warning "winget did not leave starship on PATH (exit=$LASTEXITCODE)"
    } catch {
        Write-Warning "winget failed: $($_.Exception.Message)"
    }
}

# Strategy 2: scoop
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    try {
        Write-Host "trying scoop..."
        scoop install starship
        Update-SessionPath
        if (Get-Command starship -ErrorAction SilentlyContinue) { return }
        Write-Warning "scoop did not leave starship on PATH (exit=$LASTEXITCODE)"
    } catch {
        Write-Warning "scoop failed: $($_.Exception.Message)"
    }
}

# Strategy 3: portable zip from GitHub releases (no admin).
# Per https://starship.rs/guide / README: Windows builds ship as
# starship-<arch>-pc-windows-msvc.zip/.msi under starship/starship releases.
# https://starship.rs/install.ps1 no longer exists (404), so do not use it.
Write-Host "trying GitHub releases..."
$binDir = Join-Path $HOME '.local\bin'
if (-not (Test-Path $binDir)) { New-Item -ItemType Directory -Path $binDir -Force | Out-Null }
$tempDir = $env:TEMP
if (-not $tempDir) { $tempDir = $env:TMP }
if (-not $tempDir) { $tempDir = [System.IO.Path]::GetTempPath() }
$arch = 'x86_64'
if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { $arch = 'aarch64' }
$release = Invoke-RestMethod -UseBasicParsing -Uri 'https://api.github.com/repos/starship/starship/releases/latest'
$tag = $release.tag_name
$asset = "starship-$arch-pc-windows-msvc.zip"
$url = "https://github.com/starship/starship/releases/download/$tag/$asset"
Write-Host "Downloading starship $tag ($asset)..."
$zip = Join-Path $tempDir 'starship.zip'
Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $zip
try {
    Expand-Archive -Path $zip -DestinationPath $binDir -Force
} finally {
    Remove-Item $zip -Force -ErrorAction SilentlyContinue
}
if ($env:Path -notlike "*$binDir*") { $env:Path = "$env:Path;$binDir" }
Update-SessionPath
if ($env:Path -notlike "*$binDir*") { $env:Path = "$env:Path;$binDir" }

if (-not (Get-Command starship -ErrorAction SilentlyContinue)) {
    $exe = Join-Path $binDir 'starship.exe'
    if (-not (Test-Path $exe)) {
        throw "starship installation failed (checked PATH and $exe)"
    }
    Write-Warning "starship installed at $exe but not on PATH; add $binDir to PATH"
    return
}
Write-Host "starship installed successfully"
