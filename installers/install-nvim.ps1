# install-nvim.ps1 — pre-scripted neovim installer, invocable any time.
# Managed by chezmoi: installers/install-nvim.ps1 -> ~/installers/install-nvim.ps1
# Invoke any time with: & "$HOME/installers/install-nvim.ps1"
# NOTE: uses `return`/`throw` (not `exit`) so it is safe to invoke via `&`.
# Works without admin: winget tries user scope first, then portable zip fallback.
$ErrorActionPreference = 'Stop'

function Update-SessionPath {
    $machine = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    if ($machine -and $user) { $env:Path = "$machine;$user" }
    elseif ($machine) { $env:Path = $machine }
    elseif ($user) { $env:Path = "$env:Path;$user" }
}

if (Get-Command nvim -ErrorAction SilentlyContinue) {
    Write-Host "neovim already installed: $(nvim --version | Select-Object -First 1)"
    return
}

# Strategy 1: winget (user scope avoids UAC 1602 on no-admin machines)
if (Get-Command winget -ErrorAction SilentlyContinue) {
    try {
        Write-Host "trying winget..."
        winget install --id Neovim.Neovim --exact --source winget --scope user --accept-source-agreements --accept-package-agreements
        Update-SessionPath
        if (Get-Command nvim -ErrorAction SilentlyContinue) {
            Write-Host "neovim installed via winget"
            return
        }
        Write-Warning "winget did not leave nvim on PATH (exit=$LASTEXITCODE)"
    } catch {
        Write-Warning "winget failed: $($_.Exception.Message)"
    }
} else {
    Write-Warning "winget not found; trying portable zip..."
}

# Strategy 2: portable zip from GitHub releases (no admin).
# neovim/neovim ships nvim-win64.zip (x64) and nvim-win-arm64.zip (ARM64),
# each containing nvim-winXX/bin/nvim.exe.
Write-Host "trying GitHub releases..."
$binDir = Join-Path $HOME '.local\bin'
if (-not (Test-Path $binDir)) { New-Item -ItemType Directory -Path $binDir -Force | Out-Null }
$tempDir = $env:TEMP
if (-not $tempDir) { $tempDir = $env:TMP }
if (-not $tempDir) { $tempDir = [System.IO.Path]::GetTempPath() }
$zipName = 'nvim-win64.zip'
if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { $zipName = 'nvim-win-arm64.zip' }
$release = Invoke-RestMethod -UseBasicParsing -Uri 'https://api.github.com/repos/neovim/neovim/releases/latest'
$tag = $release.tag_name
$url = "https://github.com/neovim/neovim/releases/download/$tag/$zipName"
Write-Host "Downloading neovim $tag ($zipName)..."
$zip = Join-Path $tempDir 'nvim-win.zip'
Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $zip
$extractDir = Join-Path $tempDir 'nvim-win-extract'
if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue }
try {
    Expand-Archive -Path $zip -DestinationPath $extractDir -Force
    # The zip contains nvim-win64/bin/nvim.exe plus lib/share runtime dirs,
    # so keep the whole tree (runtime files are required) and put its bin
    # on PATH instead of copying just the exe.
    $extractedRoot = Get-ChildItem -Path $extractDir -Directory | Select-Object -First 1
    if (-not $extractedRoot) { throw "unexpected layout in $zipName" }
    $targetRoot = Join-Path $HOME '.local/nvim-win64'
    if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { $targetRoot = Join-Path $HOME '.local/nvim-win-arm64' }
    if (Test-Path $targetRoot) { Remove-Item $targetRoot -Recurse -Force -ErrorAction SilentlyContinue }
    Move-Item -Path $extractedRoot.FullName -Destination $targetRoot -Force
    $nvimBinDir = Join-Path $targetRoot 'bin'
} finally {
    Remove-Item $zip -Force -ErrorAction SilentlyContinue
    Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue
}
# Persist for future shells (User scope needs no admin) and current session.
try {
    $userPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath -notlike "*$nvimBinDir*") {
        [System.Environment]::SetEnvironmentVariable('Path', "$userPath;$nvimBinDir", 'User')
    }
} catch {
    Write-Warning "could not persist PATH: $($_.Exception.Message)"
}
if ($env:Path -notlike "*$nvimBinDir*") { $env:Path = "$env:Path;$nvimBinDir" }
Update-SessionPath
if ($env:Path -notlike "*$nvimBinDir*") { $env:Path = "$env:Path;$nvimBinDir" }

if (Get-Command nvim -ErrorAction SilentlyContinue) {
    Write-Host "neovim installed via GitHub releases"
    return
}
$exe = Join-Path $nvimBinDir 'nvim.exe'
if (-not (Test-Path $exe)) {
    throw "neovim installation failed (checked PATH and $exe)"
}
Write-Warning "neovim installed at $exe but not on PATH; add $nvimBinDir to PATH"
