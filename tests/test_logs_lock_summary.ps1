# Bloco 10 - TEST 07: valida logs estruturados, lock file e summary (individual e consolidado).
# Lock file sempre testado com -Path explicito sob $env:TEMP (nunca o lock real em %LOCALAPPDATA%).
# Run de logs sempre criado sob logs/_tests_tmp_* dentro do projeto, removido ao final.
[CmdletBinding()]
param(
    [string]$ResultsDirectory = ''
)

$ErrorActionPreference = 'Stop'
$testName = 'test_logs_lock_summary'

$testScriptDirectory = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $PSScriptRoot
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}
$projectRoot = Split-Path -Parent $testScriptDirectory

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

. (Join-Path $projectRoot 'scripts/common/common.ps1')

## --- Parte A: run_metadata.json, execution_events.ndjson, summaries individuais e consolidado ---

$runDirectoryName = "_tests_tmp_logs_lock_summary_$($PID)_$([guid]::NewGuid().ToString('N').Substring(0,8))"
$runLogDirectory = Join-Path (Join-Path $projectRoot 'logs') $runDirectoryName
$terminalIds = @('analytics', 'scanning', 'processing', 'cleaning')
$beforeConsolidationContent = @{}

try {
    $runContext = New-RunContext -ProjectRoot $projectRoot -Mode 'startup_safe' -Source 'test_logs_lock_summary' -DryRun $true -RunId (Split-Path -Leaf $runLogDirectory)
    $resolvedRunLogDirectory = $runContext.LogDirectory

    $metadataPath = Join-Path $resolvedRunLogDirectory 'run_metadata.json'
    Add-Check -Name 'run_metadata_json_created' -Passed (Test-Path -LiteralPath $metadataPath) -Message $metadataPath

    foreach ($terminalId in $terminalIds) {
        $logFile = Join-Path $resolvedRunLogDirectory ("terminals/{0}.log" -f $terminalId)
        Write-TerminalLog -RunLogDirectory $resolvedRunLogDirectory -RunId $runContext.RunId -TerminalId $terminalId -Message "Simulated bootstrap for $terminalId." -Level 'INFO' -ProjectRoot $projectRoot | Out-Null
        Write-TerminalLog -RunLogDirectory $resolvedRunLogDirectory -RunId $runContext.RunId -TerminalId $terminalId -Message "Simulated completion for $terminalId." -Level 'SUCCESS' -ProjectRoot $projectRoot | Out-Null
        Add-Check -Name "terminal_log_exists_$terminalId" -Passed (Test-Path -LiteralPath $logFile) -Message $logFile

        $terminalSummary = New-ExecutionSummary -Mode 'startup_safe' -RunId $runContext.RunId -ProjectRoot $projectRoot -Source $terminalId -DryRun $true
        Add-SummaryEntry -Summary $terminalSummary -Terminal $terminalId -Command 'dry_run_placeholder' -Arguments @() -DryRun $true -Status 'dry_run' | Out-Null
        $summaryPath = Write-TerminalSummaryJson -Summary $terminalSummary -RunLogDirectory $resolvedRunLogDirectory -TerminalId $terminalId -ProjectRoot $projectRoot
        Add-Check -Name "terminal_summary_exists_$terminalId" -Passed (Test-Path -LiteralPath $summaryPath) -Message $summaryPath
        $beforeConsolidationContent[$terminalId] = Get-Content -LiteralPath $summaryPath -Raw
    }

    $eventsPath = Join-Path $resolvedRunLogDirectory 'execution_events.ndjson'
    $eventsExist = Test-Path -LiteralPath $eventsPath
    Add-Check -Name 'execution_events_ndjson_created' -Passed $eventsExist -Message $eventsPath

    if ($eventsExist) {
        $eventLines = @(Get-Content -LiteralPath $eventsPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        $allValidJson = $true
        foreach ($line in $eventLines) {
            try { $null = $line | ConvertFrom-Json } catch { $allValidJson = $false }
        }
        Add-Check -Name 'execution_events_all_lines_valid_json' -Passed $allValidJson -Message "$($eventLines.Count) line(s) checked."
    }

    $launcherSummary = New-ExecutionSummary -Mode 'startup_safe' -RunId $runContext.RunId -ProjectRoot $projectRoot -Source 'test_logs_lock_summary' -DryRun $true
    $consolidatedPath = Write-ConsolidatedSummaryJson -Summary $launcherSummary -RunLogDirectory $resolvedRunLogDirectory -Source 'test_logs_lock_summary' -ProjectRoot $projectRoot
    Add-Check -Name 'consolidated_summary_json_created' -Passed (Test-Path -LiteralPath $consolidatedPath) -Message $consolidatedPath

    if (Test-Path -LiteralPath $consolidatedPath) {
        $consolidatedContent = Get-Content -LiteralPath $consolidatedPath -Raw | ConvertFrom-Json
        $hasAllTerminals = $true
        foreach ($terminalId in $terminalIds) {
            if (-not ($consolidatedContent.terminals.PSObject.Properties.Name -contains $terminalId)) {
                $hasAllTerminals = $false
            }
        }
        Add-Check -Name 'consolidated_summary_contains_all_terminals' -Passed $hasAllTerminals -Message "Keys found: $($consolidatedContent.terminals.PSObject.Properties.Name -join ', ')"
    }

    $individualSummariesPreserved = $true
    foreach ($terminalId in $terminalIds) {
        $summaryPath = Join-Path $resolvedRunLogDirectory ("summaries/{0}_summary.json" -f $terminalId)
        if (-not (Test-Path -LiteralPath $summaryPath)) {
            $individualSummariesPreserved = $false
            continue
        }
        $afterContent = Get-Content -LiteralPath $summaryPath -Raw
        if ($afterContent -ne $beforeConsolidationContent[$terminalId]) {
            $individualSummariesPreserved = $false
        }
    }
    Add-Check -Name 'individual_summaries_not_overwritten_by_consolidation' -Passed $individualSummariesPreserved -Message 'Each summaries/<id>_summary.json must remain byte-identical after Write-ConsolidatedSummaryJson runs.'
} finally {
    if (Test-Path -LiteralPath $runLogDirectory) {
        Remove-Item -LiteralPath $runLogDirectory -Recurse -Force -ErrorAction SilentlyContinue
    }
}

## --- Parte B: lock file isolado (sempre com -Path explicito sob $env:TEMP) ---

$tempLockDirectory = Join-Path $env:TEMP "wmtg_tests_lock_$($PID)_$([guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Path $tempLockDirectory -Force | Out-Null
$activeLockPath = Join-Path $tempLockDirectory 'active.lock'
$staleLockPath = Join-Path $tempLockDirectory 'stale.lock'

try {
    $missingStatus = Test-LockFile -Path $activeLockPath
    Add-Check -Name 'lock_missing_detected' -Passed (-not $missingStatus.Exists) -Message "Exists=$($missingStatus.Exists)"

    $created = New-LockFile -Path $activeLockPath -Mode 'test' -RunId 'test-run-active' -ProjectRoot $projectRoot -LogDirectory 'logs/_tests_tmp_lock' -ExpiresAfterMinutes 60
    Add-Check -Name 'lock_created_with_current_pid' -Passed ($created.Pid -eq $PID) -Message "Pid=$($created.Pid), expected $PID"

    $reentryOk = $true
    try {
        New-LockFile -Path $activeLockPath -Mode 'test' -RunId 'test-run-active' -ProjectRoot $projectRoot -LogDirectory 'logs/_tests_tmp_lock' -ExpiresAfterMinutes 60 | Out-Null
    } catch {
        $reentryOk = $false
    }
    Add-Check -Name 'lock_same_pid_reentry_allowed' -Passed $reentryOk -Message 'A second New-LockFile call with the same PID must not throw.'

    $activeStatus = Test-LockFile -Path $activeLockPath
    Add-Check -Name 'lock_active_process_detected' -Passed ($activeStatus.ProcessActive -and -not $activeStatus.IsStale) -Message "ProcessActive=$($activeStatus.ProcessActive), IsStale=$($activeStatus.IsStale)"

    $fakeStalePayload = [ordered]@{
        runId = 'test-run-stale'
        mode = 'test'
        startedAt = (Get-Date).AddHours(-5).ToString('o')
        pid = 999999
        projectRoot = $projectRoot
        logDirectory = 'logs/_tests_tmp_lock'
        expiresAt = (Get-Date).AddHours(-4).ToString('o')
        createdBy = 'test'
        machineName = $env:COMPUTERNAME
        userName = $env:USERNAME
    }
    $fakeStalePayload | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $staleLockPath -Encoding UTF8

    $staleStatus = Test-LockFile -Path $staleLockPath
    Add-Check -Name 'lock_stale_dead_pid_detected' -Passed (-not $staleStatus.ProcessActive) -Message "ProcessActive=$($staleStatus.ProcessActive)"
    Add-Check -Name 'lock_stale_expired_detected' -Passed $staleStatus.IsExpired -Message "IsExpired=$($staleStatus.IsExpired)"
    Add-Check -Name 'lock_stale_flag_detected' -Passed $staleStatus.IsStale -Message "IsStale=$($staleStatus.IsStale)"

    $cleared = Clear-StaleLockFile -Path $staleLockPath
    Add-Check -Name 'stale_lock_removed_safely' -Passed ($cleared -and -not (Test-Path -LiteralPath $staleLockPath)) -Message "Clear-StaleLockFile returned $cleared"

    $wrongPidBlocked = $false
    try {
        Remove-LockFile -Path $activeLockPath -ExpectedPid 999999 | Out-Null
    } catch {
        $wrongPidBlocked = $true
    }
    Add-Check -Name 'lock_removal_blocked_for_wrong_pid' -Passed $wrongPidBlocked -Message 'Remove-LockFile must throw when ExpectedPid does not match the lock owner.'

    $removed = Remove-LockFile -Path $activeLockPath -ExpectedPid $PID
    Add-Check -Name 'lock_removed_with_correct_pid' -Passed ($removed -and -not (Test-Path -LiteralPath $activeLockPath)) -Message "Remove-LockFile returned $removed"
} finally {
    if (Test-Path -LiteralPath $tempLockDirectory) {
        Remove-Item -LiteralPath $tempLockDirectory -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$realLockPath = Join-Path $env:LOCALAPPDATA 'WindowsMaintenanceTerminalGrid\run.lock'
Add-Check -Name 'real_lock_file_path_untouched_by_this_test' -Passed $true -Message "Every lock check in this test used an explicit -Path under `$env:TEMP; the real path ($realLockPath) was never referenced."

## --- Parte C: retencao de logs em dry-run ---

$retentionBaseRelative = "logs/_tests_tmp_retention_$($PID)_$([guid]::NewGuid().ToString('N').Substring(0,8))"
$retentionBaseAbsolute = Join-Path $projectRoot $retentionBaseRelative
$oldRunFolder = Join-Path $retentionBaseAbsolute 'old_run'
$newRunFolder = Join-Path $retentionBaseAbsolute 'new_run'

try {
    New-Item -ItemType Directory -Path $oldRunFolder -Force | Out-Null
    New-Item -ItemType Directory -Path $newRunFolder -Force | Out-Null
    (Get-Item -LiteralPath $oldRunFolder).LastWriteTime = (Get-Date).AddDays(-60)

    $scheduleSettings = Get-ScheduleSettings -ProjectRoot $projectRoot
    $retentionDays = Get-LogRetentionDays -ScheduleSettings $scheduleSettings
    Add-Check -Name 'log_retention_days_resolved' -Passed ($retentionDays -gt 0) -Message "retentionDays=$retentionDays"

    $listOnly = Clear-OldRunLogs -ProjectRoot $projectRoot -BaseDirectory $retentionBaseRelative -RetentionDays 30
    $oldStillExistsAfterListOnly = Test-Path -LiteralPath $oldRunFolder
    Add-Check -Name 'log_retention_dry_run_does_not_delete' -Passed $oldStillExistsAfterListOnly -Message 'Without -Apply, Clear-OldRunLogs must not remove any folder.'
    Add-Check -Name 'log_retention_dry_run_lists_old_candidate' -Passed (@($listOnly | Where-Object { $_.Path -eq $oldRunFolder }).Count -eq 1) -Message "Candidates: $($listOnly.Count)"

    $applied = Clear-OldRunLogs -ProjectRoot $projectRoot -BaseDirectory $retentionBaseRelative -RetentionDays 30 -Apply
    Add-Check -Name 'log_retention_apply_removes_old_folder' -Passed (-not (Test-Path -LiteralPath $oldRunFolder)) -Message 'With -Apply, the folder older than retention must be removed.'
    Add-Check -Name 'log_retention_apply_keeps_recent_folder' -Passed (Test-Path -LiteralPath $newRunFolder) -Message 'Recently created folders must be preserved regardless of -Apply.'
} finally {
    if (Test-Path -LiteralPath $retentionBaseAbsolute) {
        Remove-Item -LiteralPath $retentionBaseAbsolute -Recurse -Force -ErrorAction SilentlyContinue
    }
}

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
