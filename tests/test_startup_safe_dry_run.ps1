# Bloco 10 - TEST 05: valida launcher_startup_safe.ps1 por inspecao estatica e pelas funcoes seguras de
# scripts/startup/startup_common.ps1. O script launcher_startup_safe.ps1 nao e invocado diretamente porque
# ele sempre delega para launcher_grid_2x2.ps1 sem -ConsolidateSummaries, o que tentaria abrir janelas reais.
[CmdletBinding()]
param(
    [string]$ResultsDirectory = ''
)

$ErrorActionPreference = 'Stop'
$testName = 'test_startup_safe_dry_run'

$testScriptDirectory = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $PSScriptRoot
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}
$projectRoot = Split-Path -Parent $testScriptDirectory
$startupDirectory = Join-Path $projectRoot 'scripts/startup'

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

$startupScripts = @('startup_common.ps1', 'launcher_startup_safe.ps1')
foreach ($scriptName in $startupScripts) {
    $scriptPath = Join-Path $startupDirectory $scriptName
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

$launcherStartupSafeContent = Get-Content -LiteralPath (Join-Path $startupDirectory 'launcher_startup_safe.ps1') -Raw
Add-Check -Name 'launcher_startup_safe_forces_dry_run_for_grid' -Passed ($launcherStartupSafeContent -match '-DryRun') -Message 'launcher_startup_safe.ps1 must pass -DryRun when invoking the grid launcher.'
Add-Check -Name 'launcher_startup_safe_calls_grid_launcher' -Passed ($launcherStartupSafeContent -match 'launcher_grid_2x2\.ps1') -Message 'launcher_startup_safe.ps1 must call launcher_grid_2x2.ps1.'
Add-Check -Name 'launcher_startup_safe_does_not_call_maintenance_real' -Passed ($launcherStartupSafeContent -notmatch 'launcher_maintenance_real\.ps1') -Message 'launcher_startup_safe.ps1 must never call launcher_maintenance_real.ps1.'
Add-Check -Name 'launcher_startup_safe_does_not_create_scheduled_task' -Passed ($launcherStartupSafeContent -notmatch 'Register-ScheduledTask') -Message 'launcher_startup_safe.ps1 must never register a scheduled task itself.'

. (Join-Path $projectRoot 'scripts/common/common.ps1')
. (Join-Path $startupDirectory 'startup_common.ps1')

$terminalsConfig = Get-TerminalsConfig -ProjectRoot $projectRoot
$scheduleSettings = Get-ScheduleSettings -ProjectRoot $projectRoot

try {
    $delayResult = Get-StartupSafeDelay -ScheduleSettings $scheduleSettings -DelaySeconds 0
    Add-Check -Name 'get_startup_safe_delay_zero_seconds' -Passed ($delayResult.Seconds -eq 0) -Message "Get-StartupSafeDelay returned Seconds=$($delayResult.Seconds), Source=$($delayResult.Source)."
} catch {
    Add-Check -Name 'get_startup_safe_delay_zero_seconds' -Passed $false -Message $_.Exception.Message
}

try {
    $safetyResult = Test-StartupSafeConfiguration -TerminalsConfig $terminalsConfig -ScheduleSettings $scheduleSettings
    Add-Check -Name 'startup_safe_configuration_is_safe' -Passed $safetyResult.IsSafe -Message ($safetyResult.Violations -join '; ')
} catch {
    Add-Check -Name 'startup_safe_configuration_is_safe' -Passed $false -Message $_.Exception.Message
}

try {
    $sampleArguments = Build-StartupSafeLauncherArguments -RunLogDirectory 'logs/_tests_tmp_sample' -NoPause
    Add-Check -Name 'startup_safe_launcher_arguments_contain_dry_run' -Passed ($sampleArguments -contains '-DryRun') -Message "Arguments: $($sampleArguments -join ' ')"
    Add-Check -Name 'startup_safe_launcher_arguments_contain_startup_safe_mode' -Passed ($sampleArguments -contains 'startup_safe') -Message "Arguments: $($sampleArguments -join ' ')"
} catch {
    Add-Check -Name 'startup_safe_launcher_arguments_contain_dry_run' -Passed $false -Message $_.Exception.Message
}

$startupRunContext = $null
try {
    $startupRunContext = New-StartupRunContext -ProjectRoot $projectRoot -ScheduleSettings $scheduleSettings
    Add-Check -Name 'new_startup_run_context_created' -Passed (Test-Path -LiteralPath $startupRunContext.LogDirectory) -Message $startupRunContext.LogDirectory

    $metadataPath = Join-Path $startupRunContext.LogDirectory 'run_metadata.json'
    Add-Check -Name 'startup_run_metadata_written' -Passed (Test-Path -LiteralPath $metadataPath) -Message $metadataPath
} catch {
    Add-Check -Name 'new_startup_run_context_created' -Passed $false -Message $_.Exception.Message
} finally {
    if ($startupRunContext -and (Test-Path -LiteralPath $startupRunContext.LogDirectory)) {
        Remove-Item -LiteralPath $startupRunContext.LogDirectory -Recurse -Force -ErrorAction SilentlyContinue
    }
}

try {
    $taskPlan = New-StartupScheduledTaskPlan -ProjectRoot $projectRoot -TerminalsConfig $terminalsConfig -ScheduleSettings $scheduleSettings -NoPause
    $planResult = Test-StartupScheduledTaskPlan -Plan $taskPlan -TerminalsConfig $terminalsConfig -ScheduleSettings $scheduleSettings
    Add-Check -Name 'startup_scheduled_task_plan_is_safe' -Passed $planResult.IsSafe -Message ($planResult.Violations -join '; ')
    Add-Check -Name 'startup_scheduled_task_plan_targets_startup_safe_script' -Passed ($taskPlan.TargetRelativePath -eq 'scripts/startup/launcher_startup_safe.ps1') -Message $taskPlan.TargetRelativePath
    Add-Check -Name 'startup_scheduled_task_plan_action_has_dry_run' -Passed ($taskPlan.ActionArguments -match '-DryRun') -Message $taskPlan.ActionArguments
} catch {
    Add-Check -Name 'startup_scheduled_task_plan_is_safe' -Passed $false -Message $_.Exception.Message
}

$existingTask = $null
try {
    $existingTask = Get-ScheduledTask -TaskName 'WindowsMaintenanceTerminalGrid' -ErrorAction SilentlyContinue
} catch {
    $existingTask = $null
}
Add-Check -Name 'no_real_scheduled_task_exists' -Passed ($null -eq $existingTask) -Message 'WindowsMaintenanceTerminalGrid scheduled task must not exist on this machine.'

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
