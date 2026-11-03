# handlers/package_handler.ps1
# Generic Package Handler implementation (PowerShell)
# This module centralizes installation logic read from manifest/dependencies.yaml.
#
# USAGE: . "$PSScriptRoot\package_handler.ps1"
#        Then call: Process-Manifest -ManifestPath $MANIFEST_PATH

$ErrorActionPreference = 'Stop'

# ============================================================================
# Install-Package <name> <type> <version> [url]
# Installs a single package based on its type.
# ============================================================================
function Install-Package {
    param(
        [Parameter(Mandatory=$true)][string]$PackageName,
        [Parameter(Mandatory=$true)][string]$PackageType,
        [string]$PackageVersion = "latest",
        [string]$PackageUrl = ""
    )

    Write-Host "`n--- [HANDLER] Attempting installation for '$PackageName' (Type: $PackageType, Version: $PackageVersion) ---"

    switch ($PackageType) {
        "standalone-binary" {
            Write-Host "INFO: Standalone binary setup for $PackageName..."
            switch ($PackageName) {
                "ripgrep" {
                    $binDir = Join-Path $HOME '.local\bin'
                    if (-not (Test-Path $binDir)) { New-Item -ItemType Directory -Path $binDir -Force | Out-Null }
                    # In production, download and extract the actual binary.
                    # For now, simulate success.
                    $rgPath = Join-Path $binDir 'rg.exe'
                    if (-not (Test-Path $rgPath)) { New-Item -ItemType File -Path $rgPath -Force | Out-Null }
                    Write-Host "SUCCESS: ripgrep simulated installed."
                }
                "starship" {
                    $binDir = Join-Path $HOME '.local\bin'
                    if (-not (Test-Path $binDir)) { New-Item -ItemType Directory -Path $binDir -Force | Out-Null }
                    # In production, use winget/scoop/GitHub releases.
                    $starshipPath = Join-Path $binDir 'starship.exe'
                    if (-not (Test-Path $starshipPath)) { New-Item -ItemType File -Path $starshipPath -Force | Out-Null }
                    Write-Host "SUCCESS: starship simulated installed."
                }
                default {
                    Write-Warning "Standalone binary handler for '$PackageName' is not implemented yet. Skipping."
                    return $false
                }
            }
        }
        "pkg-manager" {
            Write-Host "INFO: System package manager setup for $PackageName..."
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                try {
                    Write-Host "trying winget..."
                    winget install --id $PackageName --exact --source winget --accept-source-agreements --accept-package-agreements
                    Write-Host "SUCCESS: $PackageName installed via winget (simulated)."
                } catch {
                    Write-Warning "winget failed: $($_.Exception.Message)"
                    return $false
                }
            } else {
                Write-Warning "winget not found; skipping $PackageName."
                return $false
            }
        }
        "git-clone" {
            Write-Host "INFO: Git clone setup for $PackageName..."
            if ([string]::IsNullOrEmpty($PackageUrl)) {
                Write-Error "git-clone type requires a 'url' field for $PackageName."
                return $false
            }
            Write-Host "Cloning $PackageName from $PackageUrl (simulated)..."
            Write-Host "SUCCESS: $PackageName cloned (simulated)."
        }
        default {
            Write-Error "Unknown package type '$PackageType' specified for $PackageName."
            return $false
        }
    }

    Write-Host "--- [HANDLER] Finished setup attempt for $PackageName ---"
    return $true
}

# ============================================================================
# Parse-Manifest <manifest_path>
# Parses the YAML manifest and returns an array of hashtables.
# ============================================================================
function Parse-Manifest {
    param([Parameter(Mandatory=$true)][string]$ManifestPath)

    if (-not (Test-Path $ManifestPath)) {
        Write-Error "CRITICAL ERROR: Manifest file not found at $ManifestPath."
        return @()
    }

    $content = Get-Content $ManifestPath -Raw
    $packages = @()
    $currentPkg = $null
    $currentType = ""
    $currentVersion = "latest"
    $currentUrl = ""

    foreach ($line in ($content -split "`n")) {
        # Top-level key (package name, no leading whitespace)
        if ($line -match '^([a-zA-Z0-9_-]+):\s*$') {
            # Flush previous package
            if ($currentPkg) {
                $packages += @{
                    Name = $currentPkg
                    Type = $currentType
                    Version = $currentVersion
                    Url = $currentUrl
                }
            }
            $currentPkg = $Matches[1]
            $currentType = ""
            $currentVersion = "latest"
            $currentUrl = ""
        }
        # Indented field
        elseif ($line -match '^\s+type:\s*(.+)$') {
            $currentType = $Matches[1].Trim()
        }
        elseif ($line -match '^\s+version:\s*(.+)$') {
            $currentVersion = $Matches[1].Trim()
        }
        elseif ($line -match '^\s+url:\s*(.+)$') {
            $currentUrl = $Matches[1].Trim().Trim('"').Trim("'")
        }
    }

    # Flush last package
    if ($currentPkg) {
        $packages += @{
            Name = $currentPkg
            Type = $currentType
            Version = $currentVersion
            Url = $currentUrl
        }
    }

    return $packages
}

# ============================================================================
# Process-Manifest <manifest_path>
# Reads the manifest, parses all dependencies, and installs each one.
# ============================================================================
function Process-Manifest {
    param([Parameter(Mandatory=$true)][string]$ManifestPath)

    if (-not (Test-Path $ManifestPath)) {
        Write-Error "CRITICAL ERROR: Manifest file not found at $ManifestPath. Cannot proceed with installation."
        return $false
    }

    Write-Host "`n[MANIFEST HANDLER] Parsing manifest file: $ManifestPath..."
    Write-Host "--- Starting dependency graph traversal and execution... ---"

    $packages = Parse-Manifest -ManifestPath $ManifestPath
    $hasFailures = $false
    $packageCount = 0

    foreach ($pkg in $packages) {
        $packageCount++
        $result = Install-Package -PackageName $pkg.Name -PackageType $pkg.Type -PackageVersion $pkg.Version -PackageUrl $pkg.Url
        if (-not $result) {
            $hasFailures = $true
        }
    }

    Write-Host "`n--- [MANIFEST HANDLER] Processed $packageCount packages. ---"

    if ($hasFailures) {
        Write-Warning "One or more packages failed to install. Review logs above."
        return $false
    }

    return $true
}