# Windows PowerShell 5.1 profile managed by chezmoi
# https://github.com/davlug3/dotfiles

# --- Starship prompt -----------------------------------------------------
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (& starship init powershell --print-full-init)
}

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