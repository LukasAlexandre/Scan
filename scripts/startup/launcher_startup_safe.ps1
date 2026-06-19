param(
    [switch]$DryRun,
    [switch]$UseFallback,
    [switch]$NoPause,
    [int]$DelaySeconds = -1
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
$visualSettings = Get-VisualSettings -ProjectRoot $projectRoot
$scheduleSettings = Get-ScheduleSettings -ProjectRoot $projectRoot
$runLogDirectory = Resolve-StartupRunLogDirectory -ProjectRoot $projectRoot -ScheduleSettings $scheduleSettings
$startupLogFile = Join-Path $runLogDirectory 'startup_safe.log'

Write-SectionLog -Title 'Block 06 startup safe wrapper' -Terminal 'STARTUP' -LogFile $startupLogFile -ProjectRoot $projectRoot | Out-Null
Write-Log -Message "Startup safe wrapper started. DryRun='true', UseFallback='$($UseFallback.IsPresent)', NoPause='$($NoPause.IsPresent)'." -Level 'INFO' -Terminal 'STARTUP' -LogFile $startupLogFile -ProjectRoot $projectRoot | Out-Null
Write-Log -Message "Loaded visual settings version '$($visualSettings.version)'." -Level 'DEBUG' -Terminal 'STARTUP' -LogFile $startupLogFile -ProjectRoot $projectRoot | Out-Null

if (-not $DryRun.IsPresent) {
    Write-WarningLog -Message 'DryRun switch was not supplied; startup safe forces -DryRun when calling the grid launcher.' -Terminal 'STARTUP' -LogFile $startupLogFile -ProjectRoot $projectRoot | Out-Null
}

$safety = Test-StartupSafeConfiguration -TerminalsConfig $terminalsConfig -ScheduleSettings $scheduleSettings
if (-not $safety.IsSafe) {
    foreach ($violation in $safety.Violations) {
        Write-ErrorLog -Message $violation -Terminal 'STARTUP' -LogFile $startupLogFile -ProjectRoot $projectRoot | Out-Null
    }

    throw "Startup safe configuration is blocked: $($safety.Violations -join '; ')"
}

$delay = Get-StartupSafeDelay -ScheduleSettings $scheduleSettings -DelaySeconds $DelaySeconds
Write-Log -Message "Startup safe delay selected: $($delay.Seconds) second(s), source '$($delay.Source)', maximum $($delay.Maximum)." -Level 'INFO' -Terminal 'STARTUP' -LogFile $startupLogFile -ProjectRoot $projectRoot | Out-Null

if ($delay.Seconds -gt 0) {
    Start-Sleep -Seconds $delay.Seconds
}

$launcherPath = Join-Path $projectRoot 'scripts/launchers/launcher_grid_2x2.ps1'
if (-not (Test-Path -LiteralPath $launcherPath)) {
    Write-ErrorLog -Message "Grid launcher not found: $launcherPath" -Terminal 'STARTUP' -LogFile $startupLogFile -ProjectRoot $projectRoot | Out-Null
    throw "Grid launcher not found: $launcherPath"
}

$launcherArguments = Build-StartupSafeLauncherArguments -RunLogDirectory $runLogDirectory -UseFallback:$UseFallback -NoPause:$NoPause
Write-Log -Message "Calling grid launcher with: $launcherPath $(ConvertTo-StartupArgumentText -Arguments $launcherArguments)" -Level 'INFO' -Terminal 'STARTUP' -LogFile $startupLogFile -ProjectRoot $projectRoot | Out-Null

& $launcherPath @launcherArguments

Write-Log -Message 'Startup safe wrapper handed off to the grid launcher without enabling automatic startup or real mode.' -Level 'SUCCESS' -Terminal 'STARTUP' -LogFile $startupLogFile -ProjectRoot $projectRoot | Out-Null
