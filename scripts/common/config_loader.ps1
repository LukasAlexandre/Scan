function Get-ProjectRoot {
    [CmdletBinding()]
    param(
        [string]$StartPath
    )

    if ([string]::IsNullOrWhiteSpace($StartPath)) {
        if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
            $StartPath = $PSScriptRoot
        } else {
            $StartPath = (Get-Location).Path
        }
    }

    if (-not (Test-Path -LiteralPath $StartPath)) {
        throw "Start path not found: $StartPath"
    }

    $resolved = (Resolve-Path -LiteralPath $StartPath).Path
    $item = Get-Item -LiteralPath $resolved
    if (-not $item.PSIsContainer) {
        $resolved = Split-Path -Parent $resolved
    }

    while (-not [string]::IsNullOrWhiteSpace($resolved)) {
        $hasConfig = Test-Path -LiteralPath (Join-Path $resolved 'config')
        $hasDocs = Test-Path -LiteralPath (Join-Path $resolved 'Docs')
        if ($hasConfig -and $hasDocs) {
            return $resolved
        }

        $parent = Split-Path -Parent $resolved
        if ($parent -eq $resolved) {
            break
        }
        $resolved = $parent
    }

    throw "Project root not found from: $StartPath"
}

function Get-JsonConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [string]$ProjectRoot
    )

    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
        $ProjectRoot = Get-ProjectRoot
    }

    $configPath = $Path
    if (-not [System.IO.Path]::IsPathRooted($configPath)) {
        $configPath = Join-Path $ProjectRoot $configPath
    }

    if (-not (Test-Path -LiteralPath $configPath)) {
        throw "Required JSON config file not found: $configPath"
    }

    try {
        return Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
    } catch {
        throw "Invalid JSON config file '$configPath': $($_.Exception.Message)"
    }
}

function Get-TerminalsConfig {
    [CmdletBinding()]
    param(
        [string]$ProjectRoot
    )

    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
        $ProjectRoot = Get-ProjectRoot
    }

    return Get-JsonConfig -Path 'config/terminals.json' -ProjectRoot $ProjectRoot
}

function Get-VisualSettings {
    [CmdletBinding()]
    param(
        [string]$ProjectRoot
    )

    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
        $ProjectRoot = Get-ProjectRoot
    }

    return Get-JsonConfig -Path 'config/visual_settings.json' -ProjectRoot $ProjectRoot
}

function Get-ScheduleSettings {
    [CmdletBinding()]
    param(
        [string]$ProjectRoot
    )

    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
        $ProjectRoot = Get-ProjectRoot
    }

    return Get-JsonConfig -Path 'config/schedule_settings.json' -ProjectRoot $ProjectRoot
}

function Test-RequiredConfigFiles {
    [CmdletBinding()]
    param(
        [string]$ProjectRoot,
        [switch]$ThrowOnMissing
    )

    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
        $ProjectRoot = Get-ProjectRoot
    }

    $required = @(
        'config/terminals.json',
        'config/visual_settings.json',
        'config/schedule_settings.json'
    )

    $result = foreach ($relativePath in $required) {
        $fullPath = Join-Path $ProjectRoot $relativePath
        [PSCustomObject]@{
            Path = $relativePath
            FullPath = $fullPath
            Exists = Test-Path -LiteralPath $fullPath
        }
    }

    $missing = @($result | Where-Object { -not $_.Exists })
    if ($missing.Count -gt 0 -and $ThrowOnMissing) {
        $missingList = ($missing | ForEach-Object { $_.Path }) -join ', '
        throw "Required config file(s) missing: $missingList"
    }

    return $result
}
