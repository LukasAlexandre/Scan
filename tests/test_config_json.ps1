# Bloco 10 - TEST 01: valida config/terminals.json, config/visual_settings.json e config/schedule_settings.json.
# Apenas leitura de JSON. Nenhum comando de manutencao e executado.
[CmdletBinding()]
param(
    [string]$ResultsDirectory = ''
)

$ErrorActionPreference = 'Stop'
$testName = 'test_config_json'

$testScriptDirectory = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $PSScriptRoot
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}
$projectRoot = Split-Path -Parent $testScriptDirectory
. (Join-Path $projectRoot 'scripts/common/common.ps1')

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

$terminalsConfig = $null
$scheduleSettings = $null

try {
    $terminalsConfig = Get-TerminalsConfig -ProjectRoot $projectRoot
    Add-Check -Name 'terminals_json_valid' -Passed $true -Message 'config/terminals.json parsed as valid JSON.'
} catch {
    Add-Check -Name 'terminals_json_valid' -Passed $false -Message $_.Exception.Message
}

try {
    $null = Get-VisualSettings -ProjectRoot $projectRoot
    Add-Check -Name 'visual_settings_json_valid' -Passed $true -Message 'config/visual_settings.json parsed as valid JSON.'
} catch {
    Add-Check -Name 'visual_settings_json_valid' -Passed $false -Message $_.Exception.Message
}

try {
    $scheduleSettings = Get-ScheduleSettings -ProjectRoot $projectRoot
    Add-Check -Name 'schedule_settings_json_valid' -Passed $true -Message 'config/schedule_settings.json parsed as valid JSON.'
} catch {
    Add-Check -Name 'schedule_settings_json_valid' -Passed $false -Message $_.Exception.Message
}

if ($terminalsConfig) {
    $terminalCount = @($terminalsConfig.terminals).Count
    Add-Check -Name 'exactly_four_terminals' -Passed ($terminalCount -eq 4) -Message "Found $terminalCount terminal(s)."
    Add-Check -Name 'allowRealMaintenance_false' -Passed ([bool]$terminalsConfig.allowRealMaintenance -eq $false) -Message "allowRealMaintenance=$($terminalsConfig.allowRealMaintenance)"
    Add-Check -Name 'allowStartupHeavyCommands_false' -Passed ([bool]$terminalsConfig.allowStartupHeavyCommands -eq $false) -Message "allowStartupHeavyCommands=$($terminalsConfig.allowStartupHeavyCommands)"

    foreach ($terminal in @($terminalsConfig.terminals)) {
        $checkName = "terminal_$($terminal.id)_realCommandEnabled_false"
        Add-Check -Name $checkName -Passed ([bool]$terminal.realCommandEnabled -eq $false) -Message "id=$($terminal.id) realCommandEnabled=$($terminal.realCommandEnabled)"
    }
} else {
    Add-Check -Name 'terminals_json_safety_flags' -Passed $false -Message 'Skipped because terminals.json failed to load.'
}

if ($scheduleSettings) {
    Add-Check -Name 'startup_enabled_false' -Passed ([bool]$scheduleSettings.startup.enabled -eq $false) -Message "startup.enabled=$($scheduleSettings.startup.enabled)"
    Add-Check -Name 'scheduledTask_autoCreate_false' -Passed ([bool]$scheduleSettings.scheduledTask.autoCreate -eq $false) -Message "scheduledTask.autoCreate=$($scheduleSettings.scheduledTask.autoCreate)"
    Add-Check -Name 'startup_allowHeavyCommandsOnStartup_false' -Passed ([bool]$scheduleSettings.startup.allowHeavyCommandsOnStartup -eq $false) -Message "startup.allowHeavyCommandsOnStartup=$($scheduleSettings.startup.allowHeavyCommandsOnStartup)"
} else {
    Add-Check -Name 'schedule_settings_safety_flags' -Passed $false -Message 'Skipped because schedule_settings.json failed to load.'
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
