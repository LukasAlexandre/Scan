# Bloco 10 - TEST 06: valida os gates de seguranca de scripts/launchers/maintenance_real_common.ps1.
# Importante: launcher_maintenance_real.ps1 NUNCA e invocado como script neste teste, porque ele cria o
# lock file real em %LOCALAPPDATA%\WindowsMaintenanceTerminalGrid\run.lock (sem override de -Path). Em vez
# disso, as funcoes de gate (Test-MaintenanceRealGates, Test-MaintenanceConfigurationSafety,
# New-MaintenanceExecutionPlan) sao chamadas diretamente, isoladas de qualquer execucao real.
[CmdletBinding()]
param(
    [string]$ResultsDirectory = ''
)

$ErrorActionPreference = 'Stop'
$testName = 'test_maintenance_real_gates'

$testScriptDirectory = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $PSScriptRoot
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}
$projectRoot = Split-Path -Parent $testScriptDirectory
$launchersDirectory = Join-Path $projectRoot 'scripts/launchers'
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

$maintenanceScripts = @('maintenance_real_common.ps1', 'launcher_maintenance_real.ps1')
foreach ($scriptName in $maintenanceScripts) {
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
. (Join-Path $launchersDirectory 'maintenance_real_common.ps1')

# Default: nenhum switch informado -> dry-run efetivo, sem violacoes.
$gatesDefault = Test-MaintenanceRealGates
Add-Check -Name 'gates_default_is_dry_run' -Passed $gatesDefault.EffectiveDryRun -Message "EffectiveDryRun=$($gatesDefault.EffectiveDryRun)"
Add-Check -Name 'gates_default_is_approved' -Passed $gatesDefault.IsApproved -Message 'Dry-run by default must not produce violations.'

# RunReal sem token: deve bloquear mesmo com admin e AllowSessionRealMaintenance presentes.
$gatesNoToken = Test-MaintenanceRealGates -RunReal -AllowSessionRealMaintenance -IsAdmin $true -ConfirmationToken ''
Add-Check -Name 'run_real_without_token_blocked' -Passed (-not $gatesNoToken.IsApproved) -Message ($gatesNoToken.Violations -join '; ')

# RunReal sem admin: deve bloquear mesmo com token e AllowSessionRealMaintenance presentes.
$gatesNoAdmin = Test-MaintenanceRealGates -RunReal -AllowSessionRealMaintenance -IsAdmin $false -ConfirmationToken 'I_ACCEPT_WINDOWS_MAINTENANCE'
Add-Check -Name 'run_real_without_admin_blocked' -Passed (-not $gatesNoAdmin.IsApproved) -Message ($gatesNoAdmin.Violations -join '; ')

# RunReal sem -AllowSessionRealMaintenance: deve bloquear mesmo com token e admin presentes.
$gatesNoSessionFlag = Test-MaintenanceRealGates -RunReal -IsAdmin $true -ConfirmationToken 'I_ACCEPT_WINDOWS_MAINTENANCE'
Add-Check -Name 'run_real_without_session_flag_blocked' -Passed (-not $gatesNoSessionFlag.IsApproved) -Message ($gatesNoSessionFlag.Violations -join '; ')

# Todos os requisitos satisfeitos: gate aprova (apenas a checagem da funcao, nenhum comando real e disparado por isso).
$gatesAllSatisfied = Test-MaintenanceRealGates -RunReal -AllowSessionRealMaintenance -IsAdmin $true -ConfirmationToken 'I_ACCEPT_WINDOWS_MAINTENANCE'
Add-Check -Name 'run_real_with_all_requirements_is_approved' -Passed ($gatesAllSatisfied.IsApproved -and -not $gatesAllSatisfied.EffectiveDryRun) -Message "IsApproved=$($gatesAllSatisfied.IsApproved), EffectiveDryRun=$($gatesAllSatisfied.EffectiveDryRun)"

$terminalsConfig = Get-TerminalsConfig -ProjectRoot $projectRoot
try {
    $planWithoutDeepRequest = New-MaintenanceExecutionPlan -TerminalsConfig $terminalsConfig
    $planWithDeepRequest = New-MaintenanceExecutionPlan -TerminalsConfig $terminalsConfig -IncludeDeepDiskRepair

    $deepEntryWithout = @($planWithoutDeepRequest | Where-Object { $_.IsDeepDiskRepair })[0]
    $deepEntryWith = @($planWithDeepRequest | Where-Object { $_.IsDeepDiskRepair })[0]

    Add-Check -Name 'deep_disk_repair_disabled_without_switch' -Passed (-not $deepEntryWithout.Enabled) -Message "Enabled=$($deepEntryWithout.Enabled), CommandLine=$($deepEntryWithout.CommandLine)"
    Add-Check -Name 'deep_disk_repair_disabled_even_with_switch' -Passed (-not $deepEntryWith.Enabled) -Message "Enabled=$($deepEntryWith.Enabled), CommandLine=$($deepEntryWith.CommandLine)"
    Add-Check -Name 'deep_disk_repair_command_is_chkdsk_r' -Passed ($deepEntryWith.CommandLine -eq 'chkdsk C: /r') -Message $deepEntryWith.CommandLine
} catch {
    Add-Check -Name 'maintenance_execution_plan_built' -Passed $false -Message $_.Exception.Message
}

$knownMaintenanceCommands = @('dism /online /cleanup-image /restorehealth', 'sfc /scannow', 'chkdsk c: /r', 'chkdsk c: /scan', 'defrag c: /o /u /v')
foreach ($commandLine in $knownMaintenanceCommands) {
    $parts = $commandLine -split '\s+'
    $command = $parts[0]
    $arguments = @($parts | Select-Object -Skip 1)
    $isKnown = Test-WmtgKnownMaintenanceCommand -Command $command -Arguments $arguments
    Add-Check -Name "known_maintenance_command_blocked_$($command)_$($arguments -join '_')" -Passed $isKnown -Message "Command '$commandLine' must be recognized as a known/blocked maintenance command."
}

$launcherStartupSafeContent = Get-Content -LiteralPath (Join-Path $startupDirectory 'launcher_startup_safe.ps1') -Raw
Add-Check -Name 'startup_safe_never_calls_maintenance_real' -Passed ($launcherStartupSafeContent -notmatch 'launcher_maintenance_real\.ps1') -Message 'launcher_startup_safe.ps1 must never reference launcher_maintenance_real.ps1.'

# Chamada direta ao chokepoint real (Invoke-CommandWithLog) com token incorreto: deve lancar excecao
# e nunca chegar a criar o System.Diagnostics.Process para chkdsk C: /r.
$chkdskBlocked = $false
try {
    Invoke-CommandWithLog -Command 'chkdsk' -Arguments @('C:', '/r') -Mode 'maintenance_real' -DryRun $false -AllowSessionRealMaintenance $true -RequireExplicitConfirmation $true -ConfirmationToken 'wrong_token' -RequiredConfirmationToken 'I_ACCEPT_WINDOWS_MAINTENANCE' -RequireAdmin $false -AllowKnownMaintenanceCommand | Out-Null
} catch {
    $chkdskBlocked = $true
}
Add-Check -Name 'chkdsk_deep_repair_blocked_by_invoke_command_with_log' -Passed $chkdskBlocked -Message 'Invoke-CommandWithLog must throw for chkdsk C: /r when the confirmation token does not match.'

$dismProcess = Get-Process -Name 'dism' -ErrorAction SilentlyContinue
$sfcProcess = Get-Process -Name 'sfc' -ErrorAction SilentlyContinue
$chkdskProcess = Get-Process -Name 'chkdsk' -ErrorAction SilentlyContinue
$defragProcess = Get-Process -Name 'defrag' -ErrorAction SilentlyContinue
$noMaintenanceProcessRunning = (-not $dismProcess) -and (-not $sfcProcess) -and (-not $chkdskProcess) -and (-not $defragProcess)
Add-Check -Name 'no_real_maintenance_process_after_gate_checks' -Passed $noMaintenanceProcessRunning -Message 'No DISM/SFC/CHKDSK/defrag process found running after exercising all maintenance gates.'

$realLockPath = Join-Path $env:LOCALAPPDATA 'WindowsMaintenanceTerminalGrid\run.lock'
Add-Check -Name 'real_lock_file_untouched' -Passed (-not (Test-Path -LiteralPath $realLockPath)) -Message 'launcher_maintenance_real.ps1 was never invoked as a script in this test, so the real lock file must not exist because of this test.'

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
