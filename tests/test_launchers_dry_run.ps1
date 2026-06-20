# Bloco 10 - TEST 04: valida sintaxe, montagem de argumentos e fluxo seguro dos launchers.
# launcher_grid_2x2.ps1 e exercitado apenas com -ConsolidateSummaries (documentado no proprio script como
# "Intended for validation/test flows only"), que nunca abre janela real. launcher_fallback_windows.ps1 e
# launcher_maintenance_real.ps1 sao apenas analisados estaticamente (AST), nunca invocados aqui.
[CmdletBinding()]
param(
    [string]$ResultsDirectory = ''
)

$ErrorActionPreference = 'Stop'
$testName = 'test_launchers_dry_run'

$testScriptDirectory = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $PSScriptRoot
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}
$projectRoot = Split-Path -Parent $testScriptDirectory
$launchersDirectory = Join-Path $projectRoot 'scripts/launchers'

$script:checks = @()
$script:errors = @()

function Add-Check {
    param([string]$Name, [bool]$Passed, [string]$Message = '')
    $script:checks += [PSCustomObject]@{ Name = $Name; Passed = $Passed; Message = $Message }
    if (-not $Passed) { $script:errors += "$Name : $Message" }
    $status = 'FAIL'
    $color = 'Red'
    if ($Passed) { $status = 'PASS'; $color = 'Green' }
    $line = "  [$status] $Name"
    if (-not [string]::IsNullOrWhiteSpace($Message)) { $line = "$line - $Message" }
    Write-Host $line -ForegroundColor $color
}

Write-Host "=== $testName ===" -ForegroundColor Cyan
$startedAt = Get-Date

$launcherScripts = @('launcher_common.ps1', 'launcher_grid_2x2.ps1', 'launcher_maintenance_real.ps1', 'launcher_fallback_windows.ps1')
foreach ($scriptName in $launcherScripts) {
    $scriptPath = Join-Path $launchersDirectory $scriptName
    $checkName = "syntax_$scriptName"
    try {
        $parseErrors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$null, [ref]$parseErrors)
        $passed = ($parseErrors.Count -eq 0)
        $message = if ($passed) { 'No parse errors.' } else { ($parseErrors | ForEach-Object { $_.Message }) -join '; ' }
        Add-Check -Name $checkName -Passed $passed -Message $message
    } catch {
        Add-Check -Name $checkName -Passed $false -Message $_.Exception.Message
    }
}

. (Join-Path $projectRoot 'scripts/common/common.ps1')
. (Join-Path $launchersDirectory 'launcher_common.ps1')

try {
    $mode = Normalize-LauncherMode -Mode 'startup_safe'
    Add-Check -Name 'normalize_mode_startup_safe' -Passed ($mode -eq 'startup_safe') -Message "Normalize-LauncherMode returned '$mode'."
} catch {
    Add-Check -Name 'normalize_mode_startup_safe' -Passed $false -Message $_.Exception.Message
}

$blockedMaintenanceMode = $false
try {
    Assert-LauncherModeAllowedForBlock05 -Mode 'maintenance_real' -LogFile '' -ProjectRoot $projectRoot
} catch {
    $blockedMaintenanceMode = $true
}
Add-Check -Name 'grid_launcher_blocks_maintenance_real_mode' -Passed $blockedMaintenanceMode -Message 'Assert-LauncherModeAllowedForBlock05 must throw for maintenance_real.'

try {
    $terminalsConfig = Get-TerminalsConfig -ProjectRoot $projectRoot
    $terminalDefinitions = Get-LauncherTerminalDefinitions -TerminalsConfig $terminalsConfig -ProjectRoot $projectRoot
    $sampleRunLogDirectory = Join-Path $projectRoot 'logs/_tests_tmp_argument_check'
    $terminalCommands = New-LauncherTerminalCommands -TerminalDefinitions $terminalDefinitions -Mode 'startup_safe' -RunLogDirectory $sampleRunLogDirectory -NoPause

    Add-Check -Name 'terminal_commands_count_four' -Passed (@($terminalCommands).Count -eq 4) -Message "Built $(@($terminalCommands).Count) terminal command(s)."

    $allHaveDryRun = $true
    $allHaveStartupSafeMode = $true
    foreach ($command in $terminalCommands) {
        if (-not ($command.ArgumentList -contains '-DryRun')) { $allHaveDryRun = $false }
        if ($command.Mode -ne 'startup_safe') { $allHaveStartupSafeMode = $false }
    }
    Add-Check -Name 'all_terminal_commands_have_dry_run_argument' -Passed $allHaveDryRun -Message '-DryRun literal must be present in every assembled argument list.'
    Add-Check -Name 'all_terminal_commands_use_startup_safe_mode' -Passed $allHaveStartupSafeMode -Message 'Mode must remain startup_safe for this validation.'

    $layoutOrder = (@($terminalCommands) | ForEach-Object { $_.Id }) -join ','
    Add-Check -Name 'terminal_commands_fixed_2x2_order' -Passed ($layoutOrder -eq 'analytics,scanning,processing,cleaning') -Message "Order: $layoutOrder"

    $bootstrapArguments = Build-WindowsTerminalBootstrapArgumentList -TerminalCommands $terminalCommands -ProjectRoot $projectRoot
    $bootstrapArgumentText = ConvertTo-LauncherArgumentText -Arguments $bootstrapArguments
    $completionArguments = Build-WindowsTerminalGridCompletionArgumentList -TerminalCommands $terminalCommands -ProjectRoot $projectRoot
    $completionArgumentText = ConvertTo-LauncherArgumentText -Arguments $completionArguments
    $combinedArgumentText = "$bootstrapArgumentText ; $completionArgumentText"

    $splitCount = @($completionArguments | Where-Object { $_ -eq 'split-pane' }).Count
    $sizeHalfCount = @($completionArguments | Where-Object { $_ -eq '0.5' }).Count
    Add-Check -Name 'windows_terminal_bootstrap_uses_new_window' -Passed (($bootstrapArguments[0] -eq '--window') -and ($bootstrapArguments[1] -eq 'new')) -Message $bootstrapArgumentText
    Add-Check -Name 'windows_terminal_completion_targets_last_window' -Passed (($completionArguments[0] -eq '-w') -and ($completionArguments[1] -eq 'last')) -Message $completionArgumentText
    Add-Check -Name 'windows_terminal_has_three_splits' -Passed ($splitCount -eq 3) -Message "split-pane count=$splitCount"
    Add-Check -Name 'windows_terminal_splits_are_half_size' -Passed ($sizeHalfCount -eq 3) -Message "0.5 split size count=$sizeHalfCount"

    # Expected 2x2 grid: ANALYTICS (top-left) | SCANNING (top-right) over PROCESSING (bottom-left) | CLEANING (bottom-right).
    # Build order: new-tab ANALYTICS (bootstrap call, "--window new") -> [wait for window to be ready] ->
    # split-pane -H PROCESSING (below) -> move-focus up -> split-pane -V SCANNING (right of ANALYTICS)
    # -> move-focus down -> split-pane -V CLEANING (right of PROCESSING), all in the completion call (targets "-w last").
    $expectedSequencePattern = 'new-tab --title ANALYTICS .*? ; -w last split-pane -H --size 0\.5 --title PROCESSING .*? ; move-focus up ; split-pane -V --size 0\.5 --title SCANNING .*? ; move-focus down ; split-pane -V --size 0\.5 --title CLEANING '
    Add-Check -Name 'windows_terminal_grid_2x2_layout_order' -Passed ($combinedArgumentText -match $expectedSequencePattern) -Message $combinedArgumentText
    Add-Check -Name 'windows_terminal_returns_to_analytics_before_scanning_split' -Passed ($combinedArgumentText -match 'move-focus up ; split-pane -V --size 0\.5 --title SCANNING') -Message $combinedArgumentText
    Add-Check -Name 'windows_terminal_returns_to_processing_before_cleaning_split' -Passed ($combinedArgumentText -match 'move-focus down ; split-pane -V --size 0\.5 --title CLEANING') -Message $combinedArgumentText
} catch {
    Add-Check -Name 'terminal_command_assembly' -Passed $false -Message $_.Exception.Message
}

$fallbackScriptPath = Join-Path $launchersDirectory 'launcher_fallback_windows.ps1'
$fallbackContent = Get-Content -LiteralPath $fallbackScriptPath -Raw
Add-Check -Name 'fallback_script_exists' -Passed (Test-Path -LiteralPath $fallbackScriptPath) -Message $fallbackScriptPath
Add-Check -Name 'grid_launcher_references_fallback_script' -Passed ((Get-Content -LiteralPath (Join-Path $launchersDirectory 'launcher_grid_2x2.ps1') -Raw) -match 'launcher_fallback_windows\.ps1') -Message 'launcher_grid_2x2.ps1 must delegate to launcher_fallback_windows.ps1 when wt.exe is unavailable or -UseFallback is requested.'

$tempRunFolderName = "_tests_tmp_grid_consolidate_$($PID)_$([guid]::NewGuid().ToString('N').Substring(0,8))"
$tempRunDirectory = Join-Path (Join-Path $projectRoot 'logs') $tempRunFolderName
$gridLauncherPath = Join-Path $launchersDirectory 'launcher_grid_2x2.ps1'
$wtProcessIdsBefore = @(Get-Process -Name 'WindowsTerminal' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)

try {
    try {
        & $gridLauncherPath -Mode 'startup_safe' -RunLogDirectory $tempRunDirectory -DryRun -NoPause -ConsolidateSummaries | Out-Null
        Add-Check -Name 'grid_launcher_consolidate_summaries_no_throw' -Passed $true -Message 'launcher_grid_2x2.ps1 -ConsolidateSummaries executed without throwing and without opening a terminal window.'
    } catch {
        Add-Check -Name 'grid_launcher_consolidate_summaries_no_throw' -Passed $false -Message $_.Exception.Message
    }

    $summaryPath = Join-Path $tempRunDirectory 'summary.json'
    Add-Check -Name 'grid_launcher_consolidated_summary_written' -Passed (Test-Path -LiteralPath $summaryPath) -Message $summaryPath

    $wtProcessesAfter = @(Get-Process -Name 'WindowsTerminal' -ErrorAction SilentlyContinue)
    $newWtProcesses = @($wtProcessesAfter | Where-Object { $wtProcessIdsBefore -notcontains $_.Id })
    Add-Check -Name 'no_terminal_window_process_spawned' -Passed ($newWtProcesses.Count -eq 0) -Message "No new WindowsTerminal.exe process should have been spawned by -ConsolidateSummaries. Existing before=$($wtProcessIdsBefore.Count), new after=$($newWtProcesses.Count)."
} finally {
    if (Test-Path -LiteralPath $tempRunDirectory) {
        Remove-Item -LiteralPath $tempRunDirectory -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Add-Check -Name 'temp_run_directory_cleaned_up' -Passed (-not (Test-Path -LiteralPath $tempRunDirectory)) -Message $tempRunDirectory

$finishedAt = Get-Date
$passed = ($script:errors.Count -eq 0)

$result = [ordered]@{
    testName = $testName
    startedAt = $startedAt.ToString('o')
    finishedAt = $finishedAt.ToString('o')
    passed = $passed
    checks = $script:checks
    errors = $script:errors
}

if (-not [string]::IsNullOrWhiteSpace($ResultsDirectory)) {
    if (-not (Test-Path -LiteralPath $ResultsDirectory)) {
        New-Item -ItemType Directory -Path $ResultsDirectory -Force | Out-Null
    }
    $resultPath = Join-Path $ResultsDirectory ("$testName.json")
    $result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $resultPath -Encoding UTF8
}

$statusLabel = 'FAIL'
$statusColor = 'Red'
if ($passed) { $statusLabel = 'PASS'; $statusColor = 'Green' }
Write-Host "=== $testName : $statusLabel ($($script:checks.Count) checks, $($script:errors.Count) errors) ===" -ForegroundColor $statusColor

if (-not $passed) {
    exit 1
}
exit 0
