# Bloco 10 - TEST 08: valida install.ps1/uninstall.ps1 e os scripts de tarefa agendada em modo seguro.
# Nenhuma chamada usa -Apply com um token valido. Register-ScheduledTask/Unregister-ScheduledTask nunca
# sao alcancados, porque o token incorreto bloqueia antes (linha de confirmacao roda antes do bloco real).
[CmdletBinding()]
param(
    [string]$ResultsDirectory = ''
)

$ErrorActionPreference = 'Stop'
$testName = 'test_scheduled_task_dry_run'

$testScriptDirectory = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $PSScriptRoot
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}
$projectRoot = Split-Path -Parent $testScriptDirectory
$startupDirectory = Join-Path $projectRoot 'scripts/startup'
$taskName = 'WindowsMaintenanceTerminalGrid'

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

function Get-WmtgScheduledTaskOrNull {
    try {
        return Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    } catch {
        return $null
    }
}

Write-Host "=== $testName ===" -ForegroundColor Cyan
$startedAt = Get-Date

$taskBefore = Get-WmtgScheduledTaskOrNull
Add-Check -Name 'scheduled_task_absent_before_test' -Passed ($null -eq $taskBefore) -Message "$taskName must not exist before this test runs."

$installScripts = @('install.ps1')
$uninstallScripts = @('uninstall.ps1')
foreach ($scriptName in ($installScripts + $uninstallScripts)) {
    $scriptPath = Join-Path $projectRoot $scriptName
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
foreach ($scriptName in @('create_scheduled_task.ps1', 'remove_scheduled_task.ps1')) {
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

$installScriptPath = Join-Path $projectRoot 'install.ps1'
$uninstallScriptPath = Join-Path $projectRoot 'uninstall.ps1'

try {
    $installDryRunResult = & $installScriptPath
    Add-Check -Name 'install_without_apply_is_dry_run' -Passed ($installDryRunResult.DryRun -eq $true -and $installDryRunResult.Action -eq 'dry_run_create') -Message "Action=$($installDryRunResult.Action), DryRun=$($installDryRunResult.DryRun)"
    Add-Check -Name 'install_dry_run_target_is_startup_safe' -Passed ((Split-Path -Leaf $installDryRunResult.TargetPath) -eq 'launcher_startup_safe.ps1') -Message $installDryRunResult.TargetPath
    Add-Check -Name 'install_dry_run_target_is_not_maintenance_real' -Passed ($installDryRunResult.TargetPath -notmatch 'maintenance[_-]real') -Message $installDryRunResult.TargetPath
} catch {
    Add-Check -Name 'install_without_apply_is_dry_run' -Passed $false -Message $_.Exception.Message
}

try {
    $uninstallDryRunResult = & $uninstallScriptPath
    Add-Check -Name 'uninstall_without_apply_is_dry_run' -Passed ($uninstallDryRunResult.DryRun -eq $true -and $uninstallDryRunResult.Action -eq 'dry_run_remove') -Message "Action=$($uninstallDryRunResult.Action), DryRun=$($uninstallDryRunResult.DryRun)"
} catch {
    Add-Check -Name 'uninstall_without_apply_is_dry_run' -Passed $false -Message $_.Exception.Message
}

$createBlockedByWrongToken = $false
try {
    & $installScriptPath -Apply -ConfirmationToken 'wrong_token_value' | Out-Null
} catch {
    $createBlockedByWrongToken = $true
}
Add-Check -Name 'install_apply_with_wrong_token_blocked' -Passed $createBlockedByWrongToken -Message 'install.ps1 -Apply with an invalid ConfirmationToken must throw before reaching Register-ScheduledTask.'

$removeBlockedByWrongToken = $false
try {
    & $uninstallScriptPath -Apply -ConfirmationToken 'wrong_token_value' | Out-Null
} catch {
    $removeBlockedByWrongToken = $true
}
Add-Check -Name 'uninstall_apply_with_wrong_token_blocked' -Passed $removeBlockedByWrongToken -Message 'uninstall.ps1 -Apply with an invalid ConfirmationToken must throw before reaching Unregister-ScheduledTask.'

$taskAfter = Get-WmtgScheduledTaskOrNull
Add-Check -Name 'scheduled_task_absent_after_test' -Passed ($null -eq $taskAfter) -Message "$taskName must not exist after this test runs."

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
