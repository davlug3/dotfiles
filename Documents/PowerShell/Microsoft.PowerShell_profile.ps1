# PowerShell profile managed by chezmoi
# https://github.com/davlug3/dotfiles

# --- Starship prompt -----------------------------------------------------
# NOTE: Out-String collapses init output to a single string; without it
# Invoke-Expression fails with "Cannot convert Object[] to String" when
# starship prints more than one line (e.g. first run after fresh install).
# try/catch keeps the profile (and chezmoi hooks) usable when starship
# is mid-install or PATH is stale.
$starshipBinDir = Join-Path $HOME '.local\bin'
if (($env:Path -notlike "*$starshipBinDir*") -and (Test-Path $starshipBinDir)) {
    $env:Path = "$env:Path;$starshipBinDir"
}
if (Get-Command starship -ErrorAction SilentlyContinue) {
    try {
        Invoke-Expression (&starship init powershell --print-full-init | Out-String)
    } catch {
        Write-Warning "starship init failed: $($_.Exception.Message)"
    }
}

# --- Git shortcuts (chezmoi: dot_git_shortcuts.tmpl -> ~/.git_shortcuts) --
# NOTE: extensionless file, so execute contents instead of dot-sourcing;
# dot-sourcing a non-.ps1 path falls back to the shell association (Notepad).
if (Test-Path "$HOME/.git_shortcuts") { Invoke-Expression (Get-Content "$HOME/.git_shortcuts" -Raw) }

# --- Convenience aliases -------------------------------------------------

# Jump to the chezmoi source directory
function chezmoi-cd { Set-Location (chezmoi source-path) }
Set-Alias chezmoicd chezmoi-cd

# Open a file/path with the default Windows handler
function winopen {
    param([string]$Path = '.')
    Invoke-Item -Path $Path
}
Set-Alias open winopen
