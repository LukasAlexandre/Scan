function Get-LogRetentionDays {
    [CmdletBinding()]
    param(
        [object]$ScheduleSettings,
        [int]$FallbackDays = 30
    )

    $rawValue = $null
    if ($ScheduleSettings -and $ScheduleSettings.logs) {
        $rawValue = $ScheduleSettings.logs.retentionDays
    }

    $days = 0
    if ($null -eq $rawValue -or -not [int]::TryParse([string]$rawValue, [ref]$days) -or $days -le 0) {
        return $FallbackDays
    }

    return $days
}

function Clear-OldRunLogs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [string]$BaseDirectory = 'logs',
        [int]$RetentionDays = 30,
        [switch]$Apply
    )

    $resolvedLogsDirectory = Resolve-WmtgProjectPath -Path $BaseDirectory -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $resolvedLogsDirectory)) {
        return @()
    }

    $cutoff = (Get-Date).AddDays(-1 * [Math]::Abs($RetentionDays))
    $candidates = Get-ChildItem -LiteralPath $resolvedLogsDirectory -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $cutoff }

    $results = foreach ($candidate in $candidates) {
        $removed = $false
        if ($Apply.IsPresent) {
            Remove-Item -LiteralPath $candidate.FullName -Recurse -Force
            $removed = $true
        }

        [PSCustomObject]@{
            Path = $candidate.FullName
            LastWriteTime = $candidate.LastWriteTime
            AgeDays = [Math]::Round(((Get-Date) - $candidate.LastWriteTime).TotalDays, 1)
            Applied = $Apply.IsPresent
            Removed = $removed
        }
    }

    return @($results)
}
