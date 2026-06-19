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
$runContext = New-StartupRunContext -ProjectRoot $projectRoot -ScheduleSettings $scheduleSettings
$runLogDirectory = $runContext.LogDirectory
$startupLogFile = Join-Path $runLogDirectory 'startup_safe.log'

Write-SectionLog -Title 'Block 09 startup safe wrapper' -Terminal 'STARTUP' -LogFile $startupLogFile -ProjectRoot $projectRoot | Out-Null
Write-StartupLog -RunLogDirectory $runLogDirectory -RunId $runContext.RunId -Message "Startup safe wrapper started. DryRun='true', UseFallback='$($UseFallback.IsPresent)', NoPause='$($NoPause.IsPresent)'." -Level 'INFO' -ProjectRoot $projectRoot | Out-Null
Write-StartupLog -RunLogDirectory $runLogDirectory -RunId $runContext.RunId -Message "Loaded visual settings version '$($visualSettings.version)'." -Level 'DEBUG' -ProjectRoot $projectRoot | Out-Null

if (-not $DryRun.IsPresent) {
    Write-StartupLog -RunLogDirectory $runLogDirectory -RunId $runContext.RunId -Message 'DryRun switch was not supplied; startup safe forces -DryRun when calling the grid launcher.' -Level 'WARN' -ProjectRoot $projectRoot | Out-Null
}

$safety = Test-StartupSafeConfiguration -TerminalsConfig $terminalsConfig -ScheduleSettings $scheduleSettings
if (-not $safety.IsSafe) {
    foreach ($violation in $safety.Violations) {
        Write-StartupLog -RunLogDirectory $runLogDirectory -RunId $runContext.RunId -Message $violation -Level 'ERROR' -ProjectRoot $projectRoot | Out-Null
    }

    throw "Startup safe configuration is blocked: $($safety.Violations -join '; ')"
}

$lockStatus = $null

try {
    $lockStatus = New-LockFile -Mode 'startup_safe' -RunId $runContext.RunId -ProjectRoot $projectRoot -LogDirectory $runLogDirectory -ExpiresAfterMinutes 30
    Write-StartupLog -RunLogDirectory $runLogDirectory -RunId $runContext.RunId -Message "Run lock acquired at $($lockStatus.Path); duplicate startup_safe executions will be blocked until it is released." -Level 'INFO' -ProjectRoot $projectRoot | Out-Null

    $delay = Get-StartupSafeDelay -ScheduleSettings $scheduleSettings -DelaySeconds $DelaySeconds
    Write-StartupLog -RunLogDirectory $runLogDirectory -RunId $runContext.RunId -Message "Startup safe delay selected: $($delay.Seconds) second(s), source '$($delay.Source)', maximum $($delay.Maximum)." -Level 'INFO' -ProjectRoot $projectRoot | Out-Null

    if ($delay.Seconds -gt 0) {
        Start-Sleep -Seconds $delay.Seconds
    }

    $launcherPath = Join-Path $projectRoot 'scripts/launchers/launcher_grid_2x2.ps1'
    if (-not (Test-Path -LiteralPath $launcherPath)) {
        Write-StartupLog -RunLogDirectory $runLogDirectory -RunId $runContext.RunId -Message "Grid launcher not found: $launcherPath" -Level 'ERROR' -ProjectRoot $projectRoot | Out-Null
        throw "Grid launcher not found: $launcherPath"
    }

    $launcherArguments = Build-StartupSafeLauncherArguments -RunLogDirectory $runLogDirectory -UseFallback:$UseFallback -NoPause:$NoPause
    Write-StartupLog -RunLogDirectory $runLogDirectory -RunId $runContext.RunId -Message "Calling grid launcher with: $launcherPath $(ConvertTo-StartupArgumentText -Arguments $launcherArguments)" -Level 'INFO' -ProjectRoot $projectRoot | Out-Null

    & $launcherPath @launcherArguments

    Write-StartupLog -RunLogDirectory $runLogDirectory -RunId $runContext.RunId -Message 'Startup safe wrapper handed off to the grid launcher without enabling automatic startup or real mode.' -Level 'SUCCESS' -ProjectRoot $projectRoot | Out-Null
} finally {
    if ($lockStatus -and $lockStatus.Exists -and $lockStatus.Pid -eq $PID) {
        Remove-LockFile -ExpectedPid $PID | Out-Null
        Write-StartupLog -RunLogDirectory $runLogDirectory -RunId $runContext.RunId -Message 'Run lock released by startup safe wrapper before exit.' -Level 'INFO' -ProjectRoot $projectRoot | Out-Null
    }
}
