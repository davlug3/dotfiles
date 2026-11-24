# Verify that the PowerShell package handler skips work when tools are already
# installed, and that zero-byte stubs from the old simulated handler are removed.
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$tempHome = Join-Path ([IO.Path]::GetTempPath()) ("dotfiles-test-" + [guid]::NewGuid().ToString('N'))
$binDir = Join-Path $tempHome '.local\bin'
New-Item -ItemType Directory -Force -Path $binDir | Out-Null

$oldHome = $HOME
$oldPath = $env:Path
$HOME = $tempHome
$env:Path = "$binDir;$env:Path"

# Network/package tools must never be reached when everything is installed.
function winget { throw 'winget should not be called' }
function Invoke-RestMethod { throw 'Invoke-RestMethod should not be called' }
function Invoke-WebRequest { throw 'Invoke-WebRequest should not be called' }

try {
    foreach ($name in @('rg.exe', 'starship.exe', 'nvim.exe', 'tree-sitter.exe')) {
        Set-Content -Path (Join-Path $binDir $name) -Value 'fake executable'
    }

    . (Join-Path $root 'handlers\package_handler.ps1')

    foreach ($spec in @(
        @{ Name = 'ripgrep'; Type = 'standalone-binary' },
        @{ Name = 'starship'; Type = 'standalone-binary' },
        @{ Name = 'neovim'; Type = 'pkg-manager' },
        @{ Name = 'tree-sitter-cli'; Type = 'standalone-binary' }
    )) {
        Install-Package -PackageName $spec.Name -PackageType $spec.Type | Out-Null
        Install-Package -PackageName $spec.Name -PackageType $spec.Type | Out-Null
    }

    $stub = Join-Path $binDir 'rg.exe'
    Remove-Item $stub -Force
    Set-Content -Path $stub -Value ''  # zero-byte stub from the old handler
    Install-Package -PackageName 'ripgrep' -PackageType 'standalone-binary' | Out-Null
    if (Test-Path $stub) {
        throw 'stale zero-byte stub was not removed'
    }

    Write-Host 'PASS: package handler is idempotent and leaves no stubs'
} finally {
    $HOME = $oldHome
    $env:Path = $oldPath
    Remove-Item $tempHome -Recurse -Force -ErrorAction SilentlyContinue
}
