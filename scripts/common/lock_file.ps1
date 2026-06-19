function Get-LockFilePath {
    [CmdletBinding()]
    param(
        [string]$FileName = 'grid.lock'
    )

    $base = Join-Path $env:LOCALAPPDATA 'WindowsMaintenanceTerminalGrid'
    return Join-Path $base $FileName
}

function Test-LockFile {
    [CmdletBinding()]
    param(
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        $Path = Get-LockFilePath
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        return [PSCustomObject]@{
            Exists = $false
            Path = $Path
            Pid = $null
            Mode = $null
            CreatedAt = $null
            ProcessActive = $false
            IsStale = $false
        }
    }

    $content = $null
    try {
        $content = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    } catch {
        return [PSCustomObject]@{
            Exists = $true
            Path = $Path
            Pid = $null
            Mode = $null
            CreatedAt = $null
            ProcessActive = $false
            IsStale = $true
        }
    }

    $processActive = $false
    if ($content.pid) {
        $processActive = [bool](Get-Process -Id ([int]$content.pid) -ErrorAction SilentlyContinue)
    }

    return [PSCustomObject]@{
        Exists = $true
        Path = $Path
        Pid = $content.pid
        Mode = $content.mode
        CreatedAt = $content.createdAt
        ProcessActive = $processActive
        IsStale = -not $processActive
    }
}

function New-LockFile {
    [CmdletBinding()]
    param(
        [string]$Path,
        [string]$Mode = 'unknown',
        [switch]$Force
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        $Path = Get-LockFilePath
    }

    $status = Test-LockFile -Path $Path
    if ($status.Exists -and $status.ProcessActive -and -not $Force) {
        throw "Active lock file already exists for PID $($status.Pid): $Path"
    }

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $payload = [ordered]@{
        createdAt = (Get-Date).ToString('o')
        pid = $PID
        mode = $Mode
        machineName = $env:COMPUTERNAME
        userName = $env:USERNAME
    }

    $payload | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $Path -Encoding UTF8
    return Test-LockFile -Path $Path
}

function Remove-LockFile {
    [CmdletBinding()]
    param(
        [string]$Path,
        [int]$ExpectedPid
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        $Path = Get-LockFilePath
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    if ($PSBoundParameters.ContainsKey('ExpectedPid')) {
        $status = Test-LockFile -Path $Path
        if ($status.Pid -ne $ExpectedPid) {
            throw "Refusing to remove lock owned by PID $($status.Pid). Expected PID: $ExpectedPid"
        }
    }

    Remove-Item -LiteralPath $Path -Force
    return $true
}

function Clear-StaleLockFile {
    [CmdletBinding()]
    param(
        [string]$Path,
        [int]$MaxAgeMinutes = 180
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        $Path = Get-LockFilePath
    }

    $status = Test-LockFile -Path $Path
    if (-not $status.Exists) {
        return $false
    }

    $tooOld = $false
    if ($status.CreatedAt) {
        try {
            $createdAt = [DateTime]::Parse($status.CreatedAt)
            $tooOld = ((Get-Date) - $createdAt).TotalMinutes -gt $MaxAgeMinutes
        } catch {
            $tooOld = $true
        }
    }

    if ($status.IsStale -or $tooOld) {
        Remove-Item -LiteralPath $Path -Force
        return $true
    }

    return $false
}
