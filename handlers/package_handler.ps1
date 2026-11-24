# handlers/package_handler.ps1
# Generic, idempotent package handler (PowerShell) for the manifest-driven
# dotfiles. Safe to dot-source; installers set their own error preferences.
#
# USAGE (dot-sourced):
#   . handlers\package_handler.ps1
#   Process-Manifest -ManifestPath manifest\dependencies.yaml [-PackageName name]

$ErrorActionPreference = 'Stop'

function Get-BinaryName {
    param([Parameter(Mandatory=$true)][string]$Name)
    switch ($Name) {
        'ripgrep'           { return 'rg' }
        'neovim'            { return 'nvim' }
        'tree-sitter-cli'   { return 'tree-sitter' }
        default             { return $Name }
    }
}

function Update-SessionPath {
    $machine = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    if ($machine -and $user) { $env:Path = "$machine;$user" }
    elseif ($machine) { $env:Path = $machine }
    elseif ($user) { $env:Path = "$env:Path;$user" }
}

# The old simulated handler left empty .exe stubs behind. Remove only those.
function Remove-StaleStub {
    param([Parameter(Mandatory=$true)][string]$PackageName)
    $path = $null
    switch ($PackageName) {
        'ripgrep'  { $path = Join-Path $HOME '.local\bin\rg.exe' }
        'starship' { $path = Join-Path $HOME '.local\bin\starship.exe' }
    }
    if ($path -and (Test-Path $path)) {
        $item = Get-Item $path -Force
        if ($item.Length -eq 0) {
            Remove-Item $path -Force
            Write-Warning "removed invalid stub: $path"
        }
    }
}

function Test-PackageInstalled {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [string]$Type = ''
    )
    Remove-StaleStub $Name
    if ($Type -eq 'git-clone') {
        $repo = Join-Path (Join-Path (Join-Path $HOME '.local\share') $Name) '.git'
        return (Test-Path $repo)
    }
    $bin = Get-BinaryName $Name
    return [bool](Get-Command $bin -ErrorAction SilentlyContinue)
}

# ---------------------------------------------------------------------------
# Per-type installers. Every one exits early when already satisfied.
# ---------------------------------------------------------------------------

function Install-Ripgrep {
    if (Get-Command rg -ErrorAction SilentlyContinue) {
        Write-Host "ripgrep already installed: $(( & rg --version | Select-Object -First 1 ))"
        return
    }

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        try {
            Write-Host 'trying winget for ripgrep...'
            winget install --id BurntSushi.ripgrep.MSVC --exact --source winget `
                --scope user --accept-source-agreements --accept-package-agreements | Out-Null
            Update-SessionPath
            if (Get-Command rg -ErrorAction SilentlyContinue) {
                Write-Host 'ripgrep installed via winget'
                return
            }
        } catch {
            Write-Warning "winget ripgrep install failed: $($_.Exception.Message)"
        }
    }

    $binDir = Join-Path $HOME '.local\bin'
    New-Item -ItemType Directory -Force -Path $binDir | Out-Null
    $tempDir = Join-Path ([IO.Path]::GetTempPath()) ("ripgrep-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    try {
        $arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'aarch64' } else { 'x86_64' }
        $release = Invoke-RestMethod -UseBasicParsing `
            -Uri 'https://api.github.com/repos/BurntSushi/ripgrep/releases/latest'
        $tag = [string]$release.tag_name
        if ($tag -notmatch '^v?\d+\.\d+\.\d+') { throw "unexpected release tag '$tag'" }
        $asset = "ripgrep-$tag-$arch-pc-windows-msvc.zip"
        $url = "https://github.com/BurntSushi/ripgrep/releases/download/$tag/$asset"
        Write-Host "Downloading ripgrep $tag ($asset)..."
        $zip = Join-Path $tempDir 'ripgrep.zip'
        Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $zip
        $extract = Join-Path $tempDir 'extract'
        Expand-Archive -Path $zip -DestinationPath $extract -Force
        $exe = Get-ChildItem -Path $extract -Filter 'rg.exe' -Recurse | Select-Object -First 1
        if (-not $exe) { throw "rg.exe not found in $asset" }
        $staged = Join-Path $binDir ("rg.exe." + [guid]::NewGuid().ToString('N'))
        Copy-Item -Path $exe.FullName -Destination $staged -Force
        Move-Item -Path $staged -Destination (Join-Path $binDir 'rg.exe') -Force
        Update-SessionPath
        if (Get-Command rg -ErrorAction SilentlyContinue) {
            Write-Host "ripgrep installed at $binDir"
        } else {
            Write-Warning 'ripgrep installed but rg is not on PATH yet; reopen your shell'
        }
    } catch {
        Write-Warning "ripgrep install failed: $($_.Exception.Message); Telescope will use grep fallback"
    } finally {
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Install-Starship {
    if (Get-Command starship -ErrorAction SilentlyContinue) {
        Write-Host 'starship already installed'
        return
    }

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        try {
            Write-Host 'trying winget for starship...'
            winget install --id Starship.Starship --exact --source winget `
                --scope user --accept-source-agreements --accept-package-agreements | Out-Null
            Update-SessionPath
            if (Get-Command starship -ErrorAction SilentlyContinue) {
                Write-Host 'starship installed via winget'
                return
            }
        } catch {
            Write-Warning "winget starship install failed: $($_.Exception.Message)"
        }
    }

    try {
        Write-Host 'installing starship via official installer...'
        Invoke-Expression (Invoke-RestMethod -UseBasicParsing 'https://starship.rs/install.ps1')
        Update-SessionPath
        if (Get-Command starship -ErrorAction SilentlyContinue) {
            Write-Host 'starship installed via official installer'
            return
        }
    } catch {
        Write-Warning "starship install failed: $($_.Exception.Message)"
    }
    Write-Warning 'starship unavailable; prompts will skip its initialization'
}

function Install-TreeSitter {
    if ((Get-Command tree-sitter -ErrorAction SilentlyContinue) -and
        (& tree-sitter --version 2>$null | Select-Object -First 1)) {
        Write-Host "tree-sitter already installed: $(( & tree-sitter --version | Select-Object -First 1 ))"
        return
    }

    $binDir = Join-Path $HOME '.local\bin'
    New-Item -ItemType Directory -Force -Path $binDir | Out-Null
    try {
        $release = Invoke-RestMethod -UseBasicParsing `
            -Uri 'https://api.github.com/repos/tree-sitter/tree-sitter/releases/latest'
        $tag = [string]$release.tag_name
        if ($tag -notmatch '^v?\d+\.\d+\.\d+') { throw "unexpected release tag '$tag'" }
        $asset = 'tree-sitter-windows-x64.gz'
        $url = "https://github.com/tree-sitter/tree-sitter/releases/download/$tag/$asset"
        Write-Host "Downloading tree-sitter $tag ($asset)..."
        $tempDir = Join-Path ([IO.Path]::GetTempPath()) ("tree-sitter-" + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $tempDir | Out-Null
        try {
            $gz = Join-Path $tempDir 'tree-sitter.gz'
            Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $gz
            $staged = Join-Path $binDir ("tree-sitter.exe." + [guid]::NewGuid().ToString('N'))
            $inStream = [IO.File]::OpenRead($gz)
            try {
                $gzip = New-Object IO.Compression.GzipStream($inStream, [IO.Compression.CompressionMode]::Decompress)
                try {
                    $outStream = [IO.File]::Create($staged)
                    try { $gzip.CopyTo($outStream) }
                    finally { $outStream.Close() }
                }
                finally { $gzip.Close() }
            }
            finally { $inStream.Close() }
            & $staged --version 2>$null | Out-Null
            if ($LASTEXITCODE -ne 0) { throw 'downloaded tree-sitter failed smoke test' }
            Move-Item -Path $staged -Destination (Join-Path $binDir 'tree-sitter.exe') -Force
            Update-SessionPath
            Write-Host "tree-sitter installed at $binDir"
            return
        } finally {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Warning "tree-sitter download failed: $($_.Exception.Message)"
    }

    if (Get-Command npm -ErrorAction SilentlyContinue) {
        try {
            Write-Host 'tree-sitter: falling back to npm...'
            npm install -g tree-sitter-cli
            Update-SessionPath
            if (Get-Command tree-sitter -ErrorAction SilentlyContinue) {
                Write-Host 'tree-sitter installed via npm'
                return
            }
        } catch {
            Write-Warning "tree-sitter npm fallback failed: $($_.Exception.Message)"
        }
    }
    Write-Warning 'tree-sitter: install failed; skipping'
}

$wingetIds = @{
    'neovim'    = 'Neovim.Neovim'
    'lilypond'  = 'LilyPond.LilyPond'
}

function Install-PkgManager {
    param([Parameter(Mandatory=$true)][string]$Name)
    $bin = Get-BinaryName $Name
    if (Get-Command $bin -ErrorAction SilentlyContinue) {
        Write-Host "$Name already installed"
        return
    }
    if (-not $wingetIds.ContainsKey($Name)) {
        Write-Warning "${Name}: no winget package id configured; skipping"
        return
    }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Warning "${Name}: winget not found; skipping"
        return
    }
    try {
        winget install --id $wingetIds[$Name] --exact --source winget `
            --scope user --accept-source-agreements --accept-package-agreements | Out-Null
        Update-SessionPath
        if (Get-Command $bin -ErrorAction SilentlyContinue) {
            Write-Host "$Name installed via winget"
        } else {
            Write-Warning "${Name}: install finished but $bin is not on PATH yet"
        }
    } catch {
        Write-Warning "${Name}: winget install failed: $($_.Exception.Message)"
    }
}

function Install-GitClone {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [string]$Url = ''
    )
    $target = Join-Path (Join-Path $HOME '.local\share') $Name
    if (Test-Path (Join-Path $target '.git')) {
        Write-Host "$Name already cloned at $target; skipping"
        return
    }
    if (Test-Path $target) {
        Write-Warning "$target exists but is not a git repository; skipping"
        return
    }
    if ([string]::IsNullOrWhiteSpace($Url)) {
        Write-Warning "${Name}: git-clone type requires a url; skipping"
        return
    }
    $parent = Split-Path -Parent $target
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    $tempDir = Join-Path $parent (".{0}-{1}" -f $Name, [guid]::NewGuid().ToString('N'))
    try {
        git clone --depth 1 $Url $tempDir | Out-Null
        Move-Item -Path $tempDir -Destination $target
        Write-Host "$Name cloned at $target"
    } catch {
        Write-Warning "${Name}: git clone failed: $($_.Exception.Message)"
    } finally {
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

function Install-Package {
    param(
        [Parameter(Mandatory=$true)][string]$PackageName,
        [Parameter(Mandatory=$true)][string]$PackageType,
        [string]$PackageVersion = 'latest',
        [string]$PackageUrl = ''
    )
    if (Test-PackageInstalled -Name $PackageName -Type $PackageType) {
        Write-Host "$PackageName already installed; skipping"
        return $true
    }

    Write-Host "Installing $PackageName (type: $PackageType, version: $PackageVersion)..."
    switch ($PackageType) {
        'standalone-binary' {
            switch ($PackageName) {
                'ripgrep'         { Install-Ripgrep }
                'starship'        { Install-Starship }
                'tree-sitter-cli' { Install-TreeSitter }
                default {
                    Write-Warning "no standalone-binary installer for '$PackageName'; skipping"
                    return $false
                }
            }
        }
        'pkg-manager' { Install-PkgManager -Name $PackageName }
        'git-clone'   { Install-GitClone -Name $PackageName -Url $PackageUrl }
        default {
            Write-Warning "unknown package type '$PackageType' for '$PackageName'; skipping"
            return $false
        }
    }
    return $true
}

function Parse-Manifest {
    param([Parameter(Mandatory=$true)][string]$ManifestPath)
    if (-not (Test-Path $ManifestPath)) {
        Write-Warning "manifest not found at $ManifestPath"
        return @()
    }

    $packages = @()
    $currentPkg = $null
    $currentType = ''
    $currentVersion = 'latest'
    $currentUrl = ''
    foreach ($line in (Get-Content $ManifestPath -Raw) -split "`n") {
        if ($line -match '^([a-zA-Z0-9_-]+):\s*$') {
            if ($currentPkg) {
                $packages += @{ Name = $currentPkg; Type = $currentType; Version = $currentVersion; Url = $currentUrl }
            }
            $currentPkg = $Matches[1]
            $currentType = ''; $currentVersion = 'latest'; $currentUrl = ''
        }
        elseif ($line -match '^\s+type:\s*(.+)$')    { $currentType = $Matches[1].Trim() }
        elseif ($line -match '^\s+version:\s*(.+)$') { $currentVersion = $Matches[1].Trim() }
        elseif ($line -match '^\s+url:\s*(.+)$')     { $currentUrl = $Matches[1].Trim().Trim('"').Trim("'") }
    }
    if ($currentPkg) {
        $packages += @{ Name = $currentPkg; Type = $currentType; Version = $currentVersion; Url = $currentUrl }
    }
    return $packages
}

function Process-Manifest {
    param(
        [Parameter(Mandatory=$true)][string]$ManifestPath,
        [string]$PackageName = ''
    )
    if (-not (Test-Path $ManifestPath)) {
        Write-Warning "manifest not found at $ManifestPath; nothing to do"
        return $false
    }

    Write-Host "[MANIFEST HANDLER] $ManifestPath"
    $packages = Parse-Manifest -ManifestPath $ManifestPath
    $hasFailures = $false
    $count = 0
    foreach ($pkg in $packages) {
        if ($PackageName -and $pkg.Name -ne $PackageName) { continue }
        $count++
        if (-not (Install-Package -PackageName $pkg.Name -PackageType $pkg.Type `
                -PackageVersion $pkg.Version -PackageUrl $pkg.Url)) {
            $hasFailures = $true
        }
    }
    Write-Host "[MANIFEST HANDLER] processed $count package(s)"
    return (-not $hasFailures)
}
