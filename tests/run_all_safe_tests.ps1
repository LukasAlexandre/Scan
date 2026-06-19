# Bloco 10 - Executor da suite de testes seguros locais.
# Executa, em ordem, todos os scripts test_*.ps1 deste diretorio, grava logs individuais e um resumo
# consolidado em tests/results/<timestamp>/, e retorna codigo de saida diferente de zero se algum teste
# falhar. Nenhum teste aqui executa manutencao real do Windows.
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$testsDirectory = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $PSScriptRoot
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}

$runTimestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
$resultsDirectory = Join-Path (Join-Path $testsDirectory 'results') $runTimestamp
New-Item -ItemType Directory -Path $resultsDirectory -Force | Out-Null

$testOrder = @(
    'test_config_json.ps1',
    'test_common_modules.ps1',
    'test_terminal_scripts_dry_run.ps1',
    'test_launchers_dry_run.ps1',
    'test_startup_safe_dry_run.ps1',
    'test_maintenance_real_gates.ps1',
    'test_logs_lock_summary.ps1',
    'test_scheduled_task_dry_run.ps1',
    'test_security_static_scan.ps1'
)

Write-Host "=== Windows Maintenance Terminal Grid - Safe Local Test Suite ===" -ForegroundColor Cyan
Write-Host "Results directory: $resultsDirectory" -ForegroundColor Cyan

$runSummaries = @()

foreach ($testFileName in $testOrder) {
    $testPath = Join-Path $testsDirectory $testFileName
    $testBaseName = [System.IO.Path]::GetFileNameWithoutExtension($testFileName)
    $logPath = Join-Path $resultsDirectory ("$testBaseName.console.log")

    if (-not (Test-Path -LiteralPath $testPath)) {
        $runSummaries += [PSCustomObject]@{
            testName = $testBaseName
            passed = $false
            exitCode = -1
            checks = 0
            errors = @("Test script not found: $testPath")
        }
        continue
    }

    Write-Host ''
    Write-Host "--- Running $testFileName ---" -ForegroundColor Yellow

    $consoleOutput = & $testPath -ResultsDirectory $resultsDirectory 2>&1
    $exitCode = $LASTEXITCODE
    $consoleOutput | Out-String | Set-Content -LiteralPath $logPath -Encoding UTF8

    $jsonResultPath = Join-Path $resultsDirectory ("$testBaseName.json")
    $parsedResult = $null
    if (Test-Path -LiteralPath $jsonResultPath) {
        try {
            $parsedResult = Get-Content -LiteralPath $jsonResultPath -Raw | ConvertFrom-Json
        } catch {
            $parsedResult = $null
        }
    }

    if ($parsedResult) {
        $runSummaries += [PSCustomObject]@{
            testName = $testBaseName
            passed = ([bool]$parsedResult.passed -and $exitCode -eq 0)
            exitCode = $exitCode
            checks = @($parsedResult.checks).Count
            errors = @($parsedResult.errors)
        }
    } else {
        $runSummaries += [PSCustomObject]@{
            testName = $testBaseName
            passed = ($exitCode -eq 0)
            exitCode = $exitCode
            checks = 0
            errors = @("No structured result JSON found at $jsonResultPath; see $logPath for console output.")
        }
    }
}

$overallPassed = -not (@($runSummaries | Where-Object { -not $_.passed }).Count -gt 0)
$totalChecks = (@($runSummaries | ForEach-Object { $_.checks }) | Measure-Object -Sum).Sum
$totalErrors = (@($runSummaries | ForEach-Object { @($_.errors).Count }) | Measure-Object -Sum).Sum

$summaryObject = [ordered]@{
    suite = 'windows_maintenance_terminal_grid_safe_local_tests'
    runTimestamp = $runTimestamp
    resultsDirectory = $resultsDirectory
    overallPassed = $overallPassed
    totalTests = $runSummaries.Count
    totalChecks = $totalChecks
    totalErrors = $totalErrors
    tests = $runSummaries
}

$summaryJsonPath = Join-Path $resultsDirectory 'test_summary.json'
$summaryObject | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $summaryJsonPath -Encoding UTF8

$reportLines = @()
$reportLines += '# Relatorio de execucao - testes seguros locais'
$reportLines += ''
$reportLines += "Data/hora da execucao: $runTimestamp"
$reportLines += "Resultado geral: $(if ($overallPassed) { 'PASS' } else { 'FAIL' })"
$reportLines += "Total de testes: $($runSummaries.Count)"
$reportLines += "Total de checagens: $totalChecks"
$reportLines += "Total de erros: $totalErrors"
$reportLines += ''
$reportLines += '| Teste | Resultado | Exit code | Checagens | Erros |'
$reportLines += '| --- | --- | --- | --- | --- |'
foreach ($summary in $runSummaries) {
    $statusLabel = if ($summary.passed) { 'PASS' } else { 'FAIL' }
    $reportLines += "| $($summary.testName) | $statusLabel | $($summary.exitCode) | $($summary.checks) | $(@($summary.errors).Count) |"
}

$reportLines += ''
foreach ($summary in $runSummaries) {
    if (@($summary.errors).Count -gt 0) {
        $reportLines += "## Erros em $($summary.testName)"
        foreach ($errorMessage in $summary.errors) {
            $reportLines += "- $errorMessage"
        }
        $reportLines += ''
    }
}

$reportPath = Join-Path $resultsDirectory 'test_report.md'
$reportLines -join "`r`n" | Set-Content -LiteralPath $reportPath -Encoding UTF8

Write-Host ''
Write-Host "=== Suite finished: $(if ($overallPassed) { 'PASS' } else { 'FAIL' }) ($($runSummaries.Count) tests, $totalChecks checks, $totalErrors errors) ===" -ForegroundColor $(if ($overallPassed) { 'Green' } else { 'Red' })
Write-Host "Summary JSON: $summaryJsonPath"
Write-Host "Report: $reportPath"

if (-not $overallPassed) {
    exit 1
}
exit 0
