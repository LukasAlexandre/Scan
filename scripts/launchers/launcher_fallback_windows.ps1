param(
    [string]$Mode = 'startup_safe',
    [string]$RunLogDirectory = '',
    [switch]$DryRun,
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

Write-SectionLog -Title 'Block 05 fallback launcher' -Terminal 'LAUNCHER' -LogFile $context.LauncherLogFile -ProjectRoot $projectRoot | Out-Null
Write-Log -Message "Fallback launcher started with Mode='$effectiveMode', DryRun='true', NoPause='$($NoPause.IsPresent)'." -Level 'INFO' -Terminal 'LAUNCHER' -LogFile $context.LauncherLogFile -ProjectRoot $projectRoot | Out-Null

if (-not $DryRun.IsPresent) {
    Write-WarningLog -Message 'DryRun switch was not supplied; Block 05 forces -DryRun for every fallback terminal command.' -Terminal 'LAUNCHER' -LogFile $context.LauncherLogFile -ProjectRoot $projectRoot | Out-Null
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
    Write-Log -Message "Prepared fallback $($terminalCommand.Title): powershell.exe $($terminalCommand.ArgumentText)" -Level 'DEBUG' -Terminal 'LAUNCHER' -LogFile $context.LauncherLogFile -ProjectRoot $projectRoot | Out-Null
}

$launchResult = Start-TerminalFallbackWindows -TerminalCommands $terminalCommands -ProjectRoot $projectRoot -LogFile $context.LauncherLogFile
Write-Log -Message "Fallback handed off to $($launchResult.Engine) with $($launchResult.PaneCount) windows." -Level 'SUCCESS' -Terminal 'LAUNCHER' -LogFile $context.LauncherLogFile -ProjectRoot $projectRoot | Out-Null
Write-Log -Message 'No forced 2x2 positioning, scheduled task, real mode, admin request or maintenance command was used.' -Level 'SUCCESS' -Terminal 'LAUNCHER' -LogFile $context.LauncherLogFile -ProjectRoot $projectRoot | Out-Null
