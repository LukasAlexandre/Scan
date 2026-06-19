param(
    [switch]$DryRun,
    [switch]$Apply,
    [string]$ConfirmationToken = '',
    [switch]$UseFallback,
    [switch]$NoPause
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

$terminalsConfig = Get-TerminalsConfig -ProjectRoot $projectRoot
$scheduleSettings = Get-ScheduleSettings -ProjectRoot $projectRoot
$plan = New-StartupScheduledTaskPlan -ProjectRoot $projectRoot -TerminalsConfig $terminalsConfig -ScheduleSettings $scheduleSettings -UseFallback:$UseFallback -NoPause:$NoPause
$safety = Test-StartupScheduledTaskPlan -Plan $plan -TerminalsConfig $terminalsConfig -ScheduleSettings $scheduleSettings
$effectiveDryRun = ($DryRun.IsPresent -or -not $Apply.IsPresent)

Write-SectionLog -Title 'Block 08 scheduled task install plan' -Terminal 'INSTALL' | Out-Null
Write-Log -Message "TaskName: $($plan.TaskName)" -Level 'INFO' -Terminal 'INSTALL' | Out-Null
Write-Log -Message "Target: $($plan.TargetPath)" -Level 'INFO' -Terminal 'INSTALL' | Out-Null
Write-Log -Message "Action: $($plan.PowerShellExe) $($plan.ActionArguments)" -Level 'INFO' -Terminal 'INSTALL' | Out-Null
Write-Log -Message "Trigger: $($plan.Trigger), DelaySeconds: $($plan.DelaySeconds), User: $($plan.UserId), RunLevel: $($plan.RunLevel), LogonType: $($plan.LogonType)" -Level 'INFO' -Terminal 'INSTALL' | Out-Null

if (-not $safety.IsSafe) {
    foreach ($violation in $safety.Violations) {
        Write-ErrorLog -Message $violation -Terminal 'INSTALL' | Out-Null
    }

    throw "Scheduled task install blocked by unsafe plan: $($safety.Violations -join '; ')"
}

if ($effectiveDryRun) {
    Write-WarningLog -Message 'Dry-run install only. No scheduled task was created.' -Terminal 'INSTALL' | Out-Null
    return [PSCustomObject]@{
        TaskName = $plan.TaskName
        Action = 'dry_run_create'
        TargetPath = $plan.TargetPath
        ActionArguments = $plan.ActionArguments
        WouldApply = $Apply.IsPresent
        DryRun = $true
    }
}

if ($ConfirmationToken -ne 'I_ACCEPT_STARTUP_SAFE_TASK') {
    Write-ErrorLog -Message 'Apply requested, but confirmation token is invalid.' -Terminal 'INSTALL' | Out-Null
    throw 'Scheduled task creation blocked: confirmation token must be I_ACCEPT_STARTUP_SAFE_TASK.'
}

$action = New-ScheduledTaskAction -Execute $plan.PowerShellExe -Argument $plan.ActionArguments -WorkingDirectory $projectRoot
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $plan.UserId
if ($plan.DelaySeconds -gt 0) {
    $trigger.Delay = 'PT{0}S' -f $plan.DelaySeconds
}
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 8)
$settings.Hidden = $false
$principal = New-ScheduledTaskPrincipal -UserId $plan.UserId -LogonType Interactive -RunLevel Limited

Register-ScheduledTask -TaskName $plan.TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description $plan.Description -Force | Out-Null
Write-Log -Message "Scheduled task '$($plan.TaskName)' created for startup_safe dry-run launcher." -Level 'SUCCESS' -Terminal 'INSTALL' | Out-Null

return [PSCustomObject]@{
    TaskName = $plan.TaskName
    Action = 'created'
    TargetPath = $plan.TargetPath
    ActionArguments = $plan.ActionArguments
    DryRun = $false
}
