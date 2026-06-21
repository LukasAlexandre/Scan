param(
    [string]$Mode = 'startup_safe',
    [string]$RunLogDirectory = '',
    [switch]$DryRun,
    [switch]$UseFallback,
    [switch]$NoPause,
    [switch]$ConsolidateSummaries
)

$ErrorActionPreference = 'Stop'

$launcherScriptDirectory = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $PSScriptRoot
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}

. (Join-Path $launcherScriptDirectory 'launcher_common.ps1')

$projectRoot = Resolve-LauncherProjectRoot -StartPath $launcherScriptDirectory
. (Join-Path $projectRoot 'scripts/common/common.ps1')

$effectiveMode = Normalize-LauncherMode -Mode $Mode
$context = New-LauncherContext -ProjectRoot $projectRoot -Mode $effectiveMode -RunLogDirectory $RunLogDirectory -Source 'launcher_grid_2x2' -DryRun $true

Write-SectionLog -Title 'Block 09 launcher grid 2x2' -Terminal 'LAUNCHER' -LogFile $context.LauncherLogFile -ProjectRoot $projectRoot | Out-Null
Write-LauncherLog -RunLogDirectory $context.RunLogDirectory -RunId $context.RunId -Message "Launcher started with Mode='$effectiveMode', DryRun='true', UseFallback='$($UseFallback.IsPresent)', NoPause='$($NoPause.IsPresent)', RunLogDirectory='$($context.RunLogDirectory)'." -Level 'INFO' -ProjectRoot $projectRoot | Out-Null

if (-not $DryRun.IsPresent) {
    Write-LauncherLog -RunLogDirectory $context.RunLogDirectory -RunId $context.RunId -Message 'DryRun switch was not supplied; Block 05/09 forces -DryRun for every terminal command.' -Level 'WARN' -ProjectRoot $projectRoot | Out-Null
}

$lockStatus = $null

try {
    $lockStatus = New-LauncherRunLock -Context $context
    Write-LauncherLog -RunLogDirectory $context.RunLogDirectory -RunId $context.RunId -Message "Run lock acquired at $($lockStatus.Path)." -Level 'INFO' -ProjectRoot $projectRoot | Out-Null

    Assert-LauncherModeAllowedForBlock05 -Mode $effectiveMode -LogFile $context.LauncherLogFile -ProjectRoot $projectRoot

    $safety = Test-LauncherSafetyFlags -TerminalsConfig $context.TerminalsConfig -ScheduleSettings $context.ScheduleSettings
    if (-not $safety.IsSafe) {
        foreach ($violation in $safety.Violations) {
            Write-LauncherLog -RunLogDirectory $context.RunLogDirectory -RunId $context.RunId -Message $violation -Level 'ERROR' -ProjectRoot $projectRoot | Out-Null
        }
        throw "Launcher safety flags are not safe: $($safety.Violations -join '; ')"
    }

    $terminalDefinitions = Get-LauncherTerminalDefinitions -TerminalsConfig $context.TerminalsConfig -ProjectRoot $projectRoot
    Assert-LauncherTerminalScripts -TerminalDefinitions $terminalDefinitions

    $terminalCommands = New-LauncherTerminalCommands -TerminalDefinitions $terminalDefinitions -Mode $effectiveMode -RunLogDirectory $context.RunLogDirectory -NoPause:$NoPause
    foreach ($terminalCommand in $terminalCommands) {
        Write-LauncherLog -RunLogDirectory $context.RunLogDirectory -RunId $context.RunId -Message "Prepared $($terminalCommand.Title): powershell.exe $($terminalCommand.ArgumentText)" -Level 'DEBUG' -ProjectRoot $projectRoot | Out-Null
    }

    if ($ConsolidateSummaries.IsPresent) {
        Write-LauncherLog -RunLogDirectory $context.RunLogDirectory -RunId $context.RunId -Message 'ConsolidateSummaries requested: no terminal window will be opened by this invocation. Intended for validation/test flows only.' -Level 'WARN' -ProjectRoot $projectRoot | Out-Null
        Invoke-LauncherSummaryConsolidation -Context $context | Out-Null
    } else {
        $fallbackScript = Join-Path $launcherScriptDirectory 'launcher_fallback_windows.ps1'
        if ($UseFallback.IsPresent) {
            Write-LauncherLog -RunLogDirectory $context.RunLogDirectory -RunId $context.RunId -Message 'UseFallback was requested. Delegating to launcher_fallback_windows.ps1.' -Level 'WARN' -ProjectRoot $projectRoot | Out-Null
            & $fallbackScript -Mode $effectiveMode -RunLogDirectory $context.RunLogDirectory -DryRun -NoPause:$NoPause
        } elseif (-not (Test-WindowsTerminalAvailable)) {
            Write-LauncherLog -RunLogDirectory $context.RunLogDirectory -RunId $context.RunId -Message 'wt.exe was not found. Delegating to launcher_fallback_windows.ps1.' -Level 'WARN' -ProjectRoot $projectRoot | Out-Null
            & $fallbackScript -Mode $effectiveMode -RunLogDirectory $context.RunLogDirectory -DryRun -NoPause:$NoPause
        } else {
            $launchResult = Start-TerminalGrid -TerminalCommands $terminalCommands -ProjectRoot $projectRoot -VisualSettings $context.VisualSettings -LogFile $context.LauncherLogFile
            Write-LauncherLog -RunLogDirectory $context.RunLogDirectory -RunId $context.RunId -Message "Launcher handed off to $($launchResult.Engine) with $($launchResult.PaneCount) panes." -Level 'SUCCESS' -ProjectRoot $projectRoot | Out-Null
        }

        Write-LauncherLog -RunLogDirectory $context.RunLogDirectory -RunId $context.RunId -Message 'No scheduled task was created. No maintenance command was executed by the launcher. Terminals run as detached processes; the launcher does not block-wait for them, so summary.json consolidation must be triggered separately (-ConsolidateSummaries) once all terminals have finished.' -Level 'SUCCESS' -ProjectRoot $projectRoot | Out-Null
    }
} finally {
    if (Remove-LauncherRunLock -LockStatus $lockStatus) {
        Write-LauncherLog -RunLogDirectory $context.RunLogDirectory -RunId $context.RunId -Message 'Run lock released by launcher before exit.' -Level 'INFO' -ProjectRoot $projectRoot | Out-Null
    }
}
