# install-nvim.ps1 — neovim installer via manifest package manager.
# Managed by chezmoi: installers/install-nvim.ps1 -> ~/installers/install-nvim.ps1
# Refactored to rely entirely on handlers/package_handler.ps1 for execution.

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$handlerPath = Join-Path $repoRoot 'handlers\package_handler.ps1'

if (-not (Test-Path $handlerPath)) {
    $handlerPath = Join-Path $HOME '.local\share\chezmoi\handlers\package_handler.ps1'
}

if (-not (Test-Path $handlerPath)) {
    Write-Error "package_handler.ps1 not found at $handlerPath"
    return
}

. $handlerPath

$manifestPath = Join-Path $repoRoot 'manifest\dependencies.yaml'
if (-not (Test-Path $manifestPath)) {
    $manifestPath = Join-Path $HOME '.local\share\chezmoi\manifest\dependencies.yaml'
}

if (-not (Test-Path $manifestPath)) {
    Write-Error "dependencies.yaml not found at $manifestPath"
    return
}

Write-Host "--- Running Neovim installation via centralized package handler ---"

if (Process-Manifest -ManifestPath $manifestPath) {
    Write-Host "`n[SUCCESS] Dependency management run complete for Neovim." -ForegroundColor Green
} else {
    Write-Host "`n[FAILURE] Failed to run dependency handler. Check logs above." -ForegroundColor Red
}