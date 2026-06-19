function Get-LockFilePath {
    [CmdletBinding()]
    param(
        [string]$FileName = 'run.lock'
    )

    $base = Join-Path $env:LOCALAPPDATA 'WindowsMaintenanceTerminalGrid'
    return Join-Path $base $FileName
}

function Test-WmtgProcessAlive {
    [CmdletBinding()]
    param(
        [Nullable[int]]$ProcessId
    )

    if (-not $ProcessId) {
        return $false
    }

    return [bool](Get-Process -Id $ProcessId -ErrorAction SilentlyContinue)
}

function Get-WmtgCurrentUserId {
    [CmdletBinding()]
    param()

    if (-not [string]::IsNullOrWhiteSpace($env:USERDOMAIN) -and -not [string]::IsNullOrWhiteSpace($env:USERNAME)) {
        return '{0}\{1}' -f $env:USERDOMAIN, $env:USERNAME
    }

    return $env:USERNAME
}

function Read-LockFile {
    [CmdletBinding()]
    param(
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        $Path = Get-LockFilePath
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    } catch {
        return $null
    }
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
            RunId = $null
            Mode = $null
            CreatedAt = $null
            ExpiresAt = $null
            ProjectRoot = $null
            LogDirectory = $null
            CreatedBy = $null
            ProcessActive = $false
            IsExpired = $false
            IsStale = $false
        }
    }

    $content = Read-LockFile -Path $Path
    if ($null -eq $content) {
        return [PSCustomObject]@{
            Exists = $true
            Path = $Path
            Pid = $null
            RunId = $null
            Mode = $null
            CreatedAt = $null
            ExpiresAt = $null
            ProjectRoot = $null
            LogDirectory = $null
            CreatedBy = $null
            ProcessActive = $false
            IsExpired = $true
            IsStale = $true
        }
    }

    $lockPid = $null
    if ($content.pid) {
        $lockPid = [int]$content.pid
    }
    $processActive = Test-WmtgProcessAlive -ProcessId $lockPid

    $isExpired = $false
    if ($content.expiresAt) {
        try {
            $isExpired = (Get-Date) -gt ([DateTime]::Parse($content.expiresAt))
        } catch {
            $isExpired = $true
        }
    }

    return [PSCustomObject]@{
        Exists = $true
        Path = $Path
        Pid = $lockPid
        RunId = $content.runId
        Mode = $content.mode
        CreatedAt = $content.startedAt
        ExpiresAt = $content.expiresAt
        ProjectRoot = $content.projectRoot
        LogDirectory = $content.logDirectory
        CreatedBy = $content.createdBy
        ProcessActive = $processActive
        IsExpired = $isExpired
        IsStale = ((-not $processActive) -or $isExpired)
    }
}

function New-LockFile {
    [CmdletBinding()]
    param(
        [string]$Path,
        [string]$Mode = 'unknown',
        [string]$RunId,
        [string]$ProjectRoot,
        [string]$LogDirectory,
        [int]$ExpiresAfterMinutes = 180,
        [switch]$Force
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        $Path = Get-LockFilePath
    }

    $status = Test-LockFile -Path $Path
    $ownedBySelf = ($status.Exists -and $status.Pid -eq $PID)
    if ($status.Exists -and $status.ProcessActive -and -not $status.IsStale -and -not $ownedBySelf -and -not $Force) {
        throw "Active lock file already exists for PID $($status.Pid), runId '$($status.RunId)': $Path"
    }

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $startedAt = Get-Date
    $payload = [ordered]@{
        runId = $RunId
        mode = $Mode
        startedAt = $startedAt.ToString('o')
        pid = $PID
        projectRoot = $ProjectRoot
        logDirectory = $LogDirectory
        expiresAt = $startedAt.AddMinutes([Math]::Max(1, $ExpiresAfterMinutes)).ToString('o')
        createdBy = (Get-WmtgCurrentUserId)
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
        [int]$ExpectedPid,
        [string]$ExpectedRunId
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        $Path = Get-LockFilePath
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    if ($PSBoundParameters.ContainsKey('ExpectedPid') -or $PSBoundParameters.ContainsKey('ExpectedRunId')) {
        $status = Test-LockFile -Path $Path
        if ($PSBoundParameters.ContainsKey('ExpectedPid') -and $status.Pid -ne $ExpectedPid) {
            throw "Refusing to remove lock owned by PID $($status.Pid). Expected PID: $ExpectedPid"
        }
        if ($PSBoundParameters.ContainsKey('ExpectedRunId') -and $status.RunId -ne $ExpectedRunId) {
            throw "Refusing to remove lock owned by runId '$($status.RunId)'. Expected runId: $ExpectedRunId"
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

function Assert-NoActiveLock {
    [CmdletBinding()]
    param(
        [string]$Path,
        [int]$MaxAgeMinutes = 180
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        $Path = Get-LockFilePath
    }

    Clear-StaleLockFile -Path $Path -MaxAgeMinutes $MaxAgeMinutes | Out-Null
    $status = Test-LockFile -Path $Path

    if ($status.Exists -and $status.ProcessActive -and -not $status.IsStale -and $status.Pid -ne $PID) {
        throw "Active lock file already exists for PID $($status.Pid), runId '$($status.RunId)': $($status.Path)"
    }

    return $status
}
