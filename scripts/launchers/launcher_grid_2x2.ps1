param(
    [string]$Mode = 'startup_safe',
    [string]$RunLogDirectory = '',
    [switch]$DryRun,
    [switch]$UseFallback,
    [switch]$NoPause
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
$context = New-LauncherContext -ProjectRoot $projectRoot -Mode $effectiveMode -RunLogDirectory $RunLogDirectory

Write-SectionLog -Title 'Block 05 launcher grid 2x2' -Terminal 'LAUNCHER' -LogFile $context.LauncherLogFile -ProjectRoot $projectRoot | Out-Null
Write-Log -Message "Launcher started with Mode='$effectiveMode', DryRun='true', UseFallback='$($UseFallback.IsPresent)', NoPause='$($NoPause.IsPresent)', RunLogDirectory='$($context.RunLogDirectory)'." -Level 'INFO' -Terminal 'LAUNCHER' -LogFile $context.LauncherLogFile -ProjectRoot $projectRoot | Out-Null

if (-not $DryRun.IsPresent) {
    Write-WarningLog -Message 'DryRun switch was not supplied; Block 05 forces -DryRun for every terminal command.' -Terminal 'LAUNCHER' -LogFile $context.LauncherLogFile -ProjectRoot $projectRoot | Out-Null
}

Assert-LauncherModeAllowedForBlock05 -Mode $effectiveMode -LogFile $context.LauncherLogFile -ProjectRoot $projectRoot

$safety = Test-LauncherSafetyFlags -TerminalsConfig $context.TerminalsConfig -ScheduleSettings $context.ScheduleSettings
if (-not $safety.IsSafe) {
    foreach ($violation in $safety.Violations) {
        Write-ErrorLog -Message $violation -Terminal 'LAUNCHER' -LogFile $context.LauncherLogFile -ProjectRoot $projectRoot | Out-Null
    }
    throw "Launcher safety flags are not safe: $($safety.Violations -join '; ')"
}

$terminalDefinitions = Get-LauncherTerminalDefinitions -TerminalsConfig $context.TerminalsConfig -ProjectRoot $projectRoot
Assert-LauncherTerminalScripts -TerminalDefinitions $terminalDefinitions

$terminalCommands = New-LauncherTerminalCommands -TerminalDefinitions $terminalDefinitions -Mode $effectiveMode -RunLogDirectory $context.RunLogDirectory -NoPause:$NoPause
foreach ($terminalCommand in $terminalCommands) {
    Write-Log -Message "Prepared $($terminalCommand.Title): powershell.exe $($terminalCommand.ArgumentText)" -Level 'DEBUG' -Terminal 'LAUNCHER' -LogFile $context.LauncherLogFile -ProjectRoot $projectRoot | Out-Null
}

$fallbackScript = Join-Path $launcherScriptDirectory 'launcher_fallback_windows.ps1'
if ($UseFallback.IsPresent) {
    Write-WarningLog -Message 'UseFallback was requested. Delegating to launcher_fallback_windows.ps1.' -Terminal 'LAUNCHER' -LogFile $context.LauncherLogFile -ProjectRoot $projectRoot | Out-Null
    & $fallbackScript -Mode $effectiveMode -RunLogDirectory $context.RunLogDirectory -DryRun -NoPause:$NoPause
    return
}

if (-not (Test-WindowsTerminalAvailable)) {
    Write-WarningLog -Message 'wt.exe was not found. Delegating to launcher_fallback_windows.ps1.' -Terminal 'LAUNCHER' -LogFile $context.LauncherLogFile -ProjectRoot $projectRoot | Out-Null
    & $fallbackScript -Mode $effectiveMode -RunLogDirectory $context.RunLogDirectory -DryRun -NoPause:$NoPause
    return
}

$launchResult = Start-TerminalGrid -TerminalCommands $terminalCommands -ProjectRoot $projectRoot -LogFile $context.LauncherLogFile
Write-Log -Message "Launcher handed off to $($launchResult.Engine) with $($launchResult.PaneCount) panes." -Level 'SUCCESS' -Terminal 'LAUNCHER' -LogFile $context.LauncherLogFile -ProjectRoot $projectRoot | Out-Null
Write-Log -Message 'No scheduled task was created. No maintenance command was executed by the launcher.' -Level 'SUCCESS' -Terminal 'LAUNCHER' -LogFile $context.LauncherLogFile -ProjectRoot $projectRoot | Out-Null
