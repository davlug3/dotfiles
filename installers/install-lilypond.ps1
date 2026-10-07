# install-lilypond.ps1 — pre-scripted lilypond installer, invocable any time.
# Managed by chezmoi: installers/install-lilypond.ps1 -> ~/installers/install-lilypond.ps1
# Invoke any time with: & "$HOME/installers/install-lilypond.ps1"
# NOTE: uses `return` (not `exit`) so it is safe to invoke via `&`.
# LilyPond often needs admin (MSI); on no-admin machines this warns and skips
# instead of failing the whole bootstrap.
$ErrorActionPreference = 'Stop'

function Update-SessionPath {
    $machine = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    if ($machine -and $user) { $env:Path = "$machine;$user" }
    elseif ($machine) { $env:Path = $machine }
    elseif ($user) { $env:Path = "$env:Path;$user" }
}

if (Get-Command lilypond -ErrorAction SilentlyContinue) {
    Write-Host "lilypond already installed: $(lilypond --version 2>$null | Select-Object -First 1)"
    return
}

# LilyPond is published on winget as LilyPond.LilyPond
if (Get-Command winget -ErrorAction SilentlyContinue) {
    try {
        Write-Host "trying winget..."
        winget install --id LilyPond.LilyPond --exact --source winget --scope user --accept-source-agreements --accept-package-agreements
        Update-SessionPath
        if (Get-Command lilypond -ErrorAction SilentlyContinue) {
            Write-Host "lilypond installed via winget"
            return
        }
        Write-Warning "winget did not leave lilypond on PATH (exit=$LASTEXITCODE)"
    } catch {
        Write-Warning "winget failed: $($_.Exception.Message)"
    }
} else {
    Write-Warning "winget not found; skipping lilypond (needs admin MSI otherwise)"
    return
}

if (-not (Get-Command lilypond -ErrorAction SilentlyContinue)) {
    Write-Warning "lilypond not installed (likely needs admin for MSI 1602); skipping. Re-run as admin or install manually, then re-apply."
    return
}
Write-Host "lilypond installed via winget"
