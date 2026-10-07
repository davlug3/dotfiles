# install-lilypond.ps1 — pre-scripted lilypond installer, invocable any time.
# Managed by chezmoi: installers/install-lilypond.ps1 -> ~/installers/install-lilypond.ps1
# Invoke any time with: & "$HOME/installers/install-lilypond.ps1"
$ErrorActionPreference = 'Stop'

if (Get-Command lilypond -ErrorAction SilentlyContinue) {
    Write-Host "lilypond already installed: $(lilypond --version 2>$null | Select-Object -First 1)"
    return
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget not found; install App Installer from the Microsoft Store, then re-run."
}

# LilyPond is published on winget as LilyPond.LilyPond
winget install --id LilyPond.LilyPond --exact --accept-source-agreements --accept-package-agreements
$machine = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
$user = [System.Environment]::GetEnvironmentVariable('Path', 'User')
if ($machine -and $user) { $env:Path = "$machine;$user" }
Write-Host "lilypond installed via winget"
