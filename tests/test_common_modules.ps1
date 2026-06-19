# Bloco 10 - TEST 02: valida sintaxe e carregamento seguro dos modulos em scripts/common/.
# Nenhum comando de manutencao e executado; apenas parsing de AST e dot-sourcing de definicoes de funcao.
[CmdletBinding()]
param(
    [string]$ResultsDirectory = ''
)

$ErrorActionPreference = 'Stop'
$testName = 'test_common_modules'

$testScriptDirectory = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $PSScriptRoot
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}
$projectRoot = Split-Path -Parent $testScriptDirectory
$commonDirectory = Join-Path $projectRoot 'scripts/common'

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

$commonScripts = Get-ChildItem -LiteralPath $commonDirectory -Filter '*.ps1' -File

foreach ($scriptFile in $commonScripts) {
    $checkName = "syntax_$($scriptFile.Name)"
    try {
        $parseErrors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($scriptFile.FullName, [ref]$null, [ref]$parseErrors)
        $passed = ($parseErrors.Count -eq 0)
        $message = if ($passed) { 'No parse errors.' } else { ($parseErrors | ForEach-Object { $_.Message }) -join '; ' }
        Add-Check -Name $checkName -Passed $passed -Message $message
    } catch {
        Add-Check -Name $checkName -Passed $false -Message $_.Exception.Message
    }
}

try {
    . (Join-Path $commonDirectory 'common.ps1')
    Add-Check -Name 'common_ps1_dot_source' -Passed $true -Message 'common.ps1 loaded without throwing.'
} catch {
    Add-Check -Name 'common_ps1_dot_source' -Passed $false -Message $_.Exception.Message
}

$expectedFunctions = @(
    'Get-ProjectRoot', 'Get-JsonConfig', 'Get-TerminalsConfig', 'Get-VisualSettings', 'Get-ScheduleSettings', 'Test-RequiredConfigFiles',
    'Resolve-WmtgProjectPath', 'New-RunLogDirectory', 'Write-Log', 'Write-ExecutionEvent', 'Write-TerminalLog', 'Write-LauncherLog', 'Write-StartupLog', 'Write-MaintenanceLog',
    'New-RunId', 'Initialize-RunDirectory', 'Write-RunMetadata', 'Read-RunMetadata', 'New-RunContext',
    'Get-LogRetentionDays', 'Clear-OldRunLogs',
    'Show-Banner', 'Show-TerminalIntro',
    'Show-Spinner', 'Start-VisualDelay',
    'Test-IsAdmin', 'Assert-AdminOrThrow',
    'Get-LockFilePath', 'Test-LockFile', 'New-LockFile', 'Remove-LockFile', 'Clear-StaleLockFile',
    'Invoke-DryRunCommand', 'Invoke-CommandWithLog', 'Test-WmtgKnownMaintenanceCommand', 'Test-WmtgAllowedExecutable',
    'New-ExecutionSummary', 'Write-TerminalSummaryJson', 'Write-ConsolidatedSummaryJson', 'Merge-TerminalSummaries'
)

foreach ($functionName in $expectedFunctions) {
    $command = Get-Command -Name $functionName -CommandType Function -ErrorAction SilentlyContinue
    Add-Check -Name "function_available_$functionName" -Passed ($null -ne $command) -Message "Resolved via Get-Command: $($null -ne $command)"
}

# Confirma que apenas dot-sourcing (sem chamar nenhuma funcao) nao gerou processos reais nem arquivos fora do projeto.
$dismProcess = Get-Process -Name 'dism' -ErrorAction SilentlyContinue
$sfcProcess = Get-Process -Name 'sfc' -ErrorAction SilentlyContinue
$chkdskProcess = Get-Process -Name 'chkdsk' -ErrorAction SilentlyContinue
$defragProcess = Get-Process -Name 'defrag' -ErrorAction SilentlyContinue
$noMaintenanceProcessRunning = (-not $dismProcess) -and (-not $sfcProcess) -and (-not $chkdskProcess) -and (-not $defragProcess)
Add-Check -Name 'no_maintenance_process_after_import' -Passed $noMaintenanceProcessRunning -Message 'No DISM/SFC/CHKDSK/defrag process found running after dot-sourcing common.ps1.'

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
