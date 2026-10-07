# install-nvim.ps1 — pre-scripted neovim installer, invocable any time.
# Managed by chezmoi: installers/install-nvim.ps1 -> ~/installers/install-nvim.ps1
# Invoke any time with: & "$HOME/installers/install-nvim.ps1"
$ErrorActionPreference = 'Stop'

if (Get-Command nvim -ErrorAction SilentlyContinue) {
    Write-Host "neovim already installed: $(nvim --version | Select-Object -First 1)"
    return
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget not found; install App Installer from the Microsoft Store, then re-run."
}

winget install --id Neovim.Neovim --exact --source winget --accept-source-agreements --accept-package-agreements
$machine = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
$user = [System.Environment]::GetEnvironmentVariable('Path', 'User')
if ($machine -and $user) { $env:Path = "$machine;$user" }
Write-Host "neovim installed via winget"
