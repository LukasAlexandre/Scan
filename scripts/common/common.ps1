$commonScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

$commonScripts = @(
    'config_loader.ps1',
    'logger.ps1',
    'run_context.ps1',
    'log_retention.ps1',
    'banner.ps1',
    'spinner.ps1',
    'admin_check.ps1',
    'lock_file.ps1',
    'command_runner.ps1',
    'summary_writer.ps1'
)

foreach ($scriptName in $commonScripts) {
    $scriptPath = Join-Path $commonScriptDirectory $scriptName
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        throw "Common script not found: $scriptPath"
    }
    . $scriptPath
}

$requiredFunctions = @(
    'Get-ProjectRoot',
    'Get-JsonConfig',
    'Get-TerminalsConfig',
    'Get-VisualSettings',
    'Get-ScheduleSettings',
    'Test-RequiredConfigFiles',
    'New-RunLogDirectory',
    'Write-Log',
    'Write-ColoredLog',
    'Write-SectionLog',
    'Write-WarningLog',
    'Write-ErrorLog',
    'Write-ExecutionEvent',
    'Write-TerminalLog',
    'Write-LauncherLog',
    'Write-StartupLog',
    'Write-MaintenanceLog',
    'New-RunId',
    'New-RunContext',
    'Initialize-RunDirectory',
    'Write-RunMetadata',
    'Read-RunMetadata',
    'Get-LogRetentionDays',
    'Clear-OldRunLogs',
    'Show-Banner',
    'Show-TerminalIntro',
    'Show-TypingText',
    'Write-TypewriterText',
    'Show-LoadingBar',
    'Show-Spinner',
    'Start-VisualDelay',
    'Test-IsAdmin',
    'Assert-AdminOrThrow',
    'Get-LockFilePath',
    'Read-LockFile',
    'Test-LockFile',
    'New-LockFile',
    'Remove-LockFile',
    'Clear-StaleLockFile',
    'Assert-NoActiveLock',
    'Invoke-CommandWithLog',
    'Invoke-DryRunCommand',
    'Write-SummaryJson',
    'Write-TerminalSummaryJson',
    'Merge-TerminalSummaries',
    'Write-ConsolidatedSummaryJson',
    'New-ExecutionSummary',
    'Add-SummaryEntry'
)

$missingFunctions = @(
    foreach ($functionName in $requiredFunctions) {
        if (-not (Get-Command -Name $functionName -CommandType Function -ErrorAction SilentlyContinue)) {
            $functionName
        }
    }
)

if ($missingFunctions.Count -gt 0) {
    throw "Missing common function(s): $($missingFunctions -join ', ')"
}
