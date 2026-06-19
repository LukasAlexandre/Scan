# Bloco 10 - TEST 03: valida em dry-run os 4 scripts de terminal e o terminal_runner.ps1.
# Cada script roda com -DryRun -NoPause em um RunLogDirectory temporario dentro de logs/, removido ao final.
[CmdletBinding()]
param(
    [string]$ResultsDirectory = ''
)

$ErrorActionPreference = 'Stop'
$testName = 'test_terminal_scripts_dry_run'

$testScriptDirectory = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $PSScriptRoot
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}
$projectRoot = Split-Path -Parent $testScriptDirectory
$terminalsDirectory = Join-Path $projectRoot 'scripts/terminals'

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

$scriptsToCheckSyntax = @('terminal_runner.ps1', 'analytics_dism.ps1', 'scanning_sfc.ps1', 'processing_chkdsk.ps1', 'cleaning_optimize.ps1')
foreach ($scriptName in $scriptsToCheckSyntax) {
    $scriptPath = Join-Path $terminalsDirectory $scriptName
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

$terminalEntries = @(
    @{ Id = 'analytics'; Script = 'analytics_dism.ps1' },
    @{ Id = 'scanning'; Script = 'scanning_sfc.ps1' },
    @{ Id = 'processing'; Script = 'processing_chkdsk.ps1' },
    @{ Id = 'cleaning'; Script = 'cleaning_optimize.ps1' }
)

$tempRunFolderName = "_tests_tmp_terminal_dry_run_$($PID)_$([guid]::NewGuid().ToString('N').Substring(0,8))"
$tempRunDirectory = Join-Path (Join-Path $projectRoot 'logs') $tempRunFolderName

try {
    foreach ($entry in $terminalEntries) {
        $scriptPath = Join-Path $terminalsDirectory $entry.Script
        $checkName = "dry_run_$($entry.Id)"
        try {
            & $scriptPath -Mode 'startup_safe' -RunLogDirectory $tempRunDirectory -NoPause -DryRun | Out-Null
            Add-Check -Name $checkName -Passed $true -Message "$($entry.Script) executed with -DryRun -NoPause without throwing."
        } catch {
            Add-Check -Name $checkName -Passed $false -Message $_.Exception.Message
        }

        $logPath = Join-Path $tempRunDirectory ("terminals/{0}.log" -f $entry.Id)
        Add-Check -Name "log_exists_$($entry.Id)" -Passed (Test-Path -LiteralPath $logPath) -Message $logPath

        $summaryPath = Join-Path $tempRunDirectory ("summaries/{0}_summary.json" -f $entry.Id)
        Add-Check -Name "summary_exists_$($entry.Id)" -Passed (Test-Path -LiteralPath $summaryPath) -Message $summaryPath

        if (Test-Path -LiteralPath $summaryPath) {
            try {
                $summaryContent = Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json
                Add-Check -Name "summary_valid_json_$($entry.Id)" -Passed $true -Message 'Summary parsed as valid JSON.'
                $summaryText = ($summaryContent | ConvertTo-Json -Depth 8)
                $hasRealCommandKeyword = $summaryText -match 'real_execution' -or $summaryText -match 'completed_real'
                Add-Check -Name "summary_no_real_status_$($entry.Id)" -Passed (-not $hasRealCommandKeyword) -Message 'Summary does not contain a real-execution status.'
            } catch {
                Add-Check -Name "summary_valid_json_$($entry.Id)" -Passed $false -Message $_.Exception.Message
            }
        }
    }

    $eventsPath = Join-Path $tempRunDirectory 'execution_events.ndjson'
    Add-Check -Name 'execution_events_exists' -Passed (Test-Path -LiteralPath $eventsPath) -Message $eventsPath

    $dismProcess = Get-Process -Name 'dism' -ErrorAction SilentlyContinue
    $sfcProcess = Get-Process -Name 'sfc' -ErrorAction SilentlyContinue
    $chkdskProcess = Get-Process -Name 'chkdsk' -ErrorAction SilentlyContinue
    $defragProcess = Get-Process -Name 'defrag' -ErrorAction SilentlyContinue
    $noMaintenanceProcessRunning = (-not $dismProcess) -and (-not $sfcProcess) -and (-not $chkdskProcess) -and (-not $defragProcess)
    Add-Check -Name 'no_real_maintenance_process_detected' -Passed $noMaintenanceProcessRunning -Message 'No DISM/SFC/CHKDSK/defrag process found running after dry-run of all 4 terminals.'
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
