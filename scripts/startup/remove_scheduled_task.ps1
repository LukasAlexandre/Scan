param(
    [switch]$DryRun,
    [switch]$Apply,
    [string]$ConfirmationToken = ''
)

$ErrorActionPreference = 'Stop'

$startupScriptDirectory = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $PSScriptRoot
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}

. (Join-Path $startupScriptDirectory 'startup_common.ps1')

$projectRoot = Resolve-StartupProjectRoot -StartPath $startupScriptDirectory
. (Join-Path $projectRoot 'scripts/common/common.ps1')

$scheduleSettings = Get-ScheduleSettings -ProjectRoot $projectRoot
$taskName = $scheduleSettings.scheduledTask.taskName
if ([string]::IsNullOrWhiteSpace($taskName)) {
    $taskName = 'WindowsMaintenanceTerminalGrid'
}
if ($taskName -ne 'WindowsMaintenanceTerminalGrid') {
    throw 'Scheduled task removal blocked: unexpected task name in configuration.'
}

$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
$exists = ($null -ne $task)
$effectiveDryRun = ($DryRun.IsPresent -or -not $Apply.IsPresent)

Write-SectionLog -Title 'Block 08 scheduled task removal plan' -Terminal 'UNINSTALL' | Out-Null
Write-Log -Message "TaskName: $taskName" -Level 'INFO' -Terminal 'UNINSTALL' | Out-Null
Write-Log -Message "TaskExists: $exists" -Level 'INFO' -Terminal 'UNINSTALL' | Out-Null

if ($effectiveDryRun) {
    Write-WarningLog -Message 'Dry-run removal only. No scheduled task was removed.' -Terminal 'UNINSTALL' | Out-Null
    return [PSCustomObject]@{
        TaskName = $taskName
        Action = 'dry_run_remove'
        Exists = $exists
        DryRun = $true
    }
}

if ($ConfirmationToken -ne 'I_ACCEPT_REMOVE_STARTUP_SAFE_TASK') {
    Write-ErrorLog -Message 'Apply requested, but removal confirmation token is invalid.' -Terminal 'UNINSTALL' | Out-Null
    throw 'Scheduled task removal blocked: confirmation token must be I_ACCEPT_REMOVE_STARTUP_SAFE_TASK.'
}

if (-not $exists) {
    Write-WarningLog -Message "Scheduled task '$taskName' does not exist. Nothing to remove." -Terminal 'UNINSTALL' | Out-Null
    return [PSCustomObject]@{
        TaskName = $taskName
        Action = 'not_found'
        Exists = $false
        DryRun = $false
    }
}

Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
Write-Log -Message "Scheduled task '$taskName' removed." -Level 'SUCCESS' -Terminal 'UNINSTALL' | Out-Null

return [PSCustomObject]@{
    TaskName = $taskName
    Action = 'removed'
    Exists = $true
    DryRun = $false
}
