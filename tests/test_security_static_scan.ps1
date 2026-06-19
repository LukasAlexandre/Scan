# Bloco 10 - TEST 09: varredura estatica de seguranca (somente alerta, nunca apaga nada).
# Verifica se padroes sensiveis (comandos de manutencao, criacao de tarefa agendada, autoelevacao,
# alteracao de registro, shell:startup, --force) aparecem apenas nos arquivos onde sao esperados.
[CmdletBinding()]
param(
    [string]$ResultsDirectory = ''
)

$ErrorActionPreference = 'Stop'
$testName = 'test_security_static_scan'

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

$scannedFiles = @(Get-ChildItem -LiteralPath (Join-Path $projectRoot 'scripts') -Recurse -Filter '*.ps1' -File)
$scannedFiles += Get-Item -LiteralPath (Join-Path $projectRoot 'install.ps1')
$scannedFiles += Get-Item -LiteralPath (Join-Path $projectRoot 'uninstall.ps1')

function Find-PatternViolations {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Pattern,

        [string[]]$AllowedFileNames = @()
    )

    $violations = @()
    foreach ($file in $scannedFiles) {
        $content = Get-Content -LiteralPath $file.FullName -Raw
        if ($content -match $Pattern) {
            if ($AllowedFileNames -notcontains $file.Name) {
                $violations += $file.FullName
            }
        }
    }
    return @($violations)
}

function Find-PatternViolationsInDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Pattern,

        [Parameter(Mandatory = $true)]
        [string]$DirectoryNameFilter
    )

    $violations = @()
    foreach ($file in $scannedFiles) {
        if ($file.FullName -notmatch [regex]::Escape($DirectoryNameFilter)) {
            continue
        }
        $content = Get-Content -LiteralPath $file.FullName -Raw
        if ($content -match $Pattern) {
            $violations += $file.FullName
        }
    }
    return @($violations)
}

$registerTaskViolations = Find-PatternViolations -Pattern '(?<!Un)Register-ScheduledTask' -AllowedFileNames @('create_scheduled_task.ps1')
Add-Check -Name 'register_scheduled_task_only_in_permitted_script' -Passed ($registerTaskViolations.Count -eq 0) -Message ($registerTaskViolations -join '; ')

$unregisterTaskViolations = Find-PatternViolations -Pattern 'Unregister-ScheduledTask' -AllowedFileNames @('remove_scheduled_task.ps1')
Add-Check -Name 'unregister_scheduled_task_only_in_permitted_script' -Passed ($unregisterTaskViolations.Count -eq 0) -Message ($unregisterTaskViolations -join '; ')

$schtasksViolations = Find-PatternViolations -Pattern 'schtasks(\.exe)?\s' -AllowedFileNames @()
Add-Check -Name 'no_raw_schtasks_exe_usage' -Passed ($schtasksViolations.Count -eq 0) -Message ($schtasksViolations -join '; ')

$runLevelHighestViolations = Find-PatternViolations -Pattern 'RunLevel[^\n]{0,40}Highest' -AllowedFileNames @()
Add-Check -Name 'no_runlevel_highest_anywhere' -Passed ($runLevelHighestViolations.Count -eq 0) -Message ($runLevelHighestViolations -join '; ')

$startupReferencesMaintenanceReal = Find-PatternViolationsInDirectory -Pattern 'launcher_maintenance_real\.ps1' -DirectoryNameFilter 'scripts\startup'
Add-Check -Name 'startup_scripts_never_reference_maintenance_real' -Passed ($startupReferencesMaintenanceReal.Count -eq 0) -Message ($startupReferencesMaintenanceReal -join '; ')

$registryViolations = Find-PatternViolations -Pattern '(HKLM:|HKCU:|Registry::|New-ItemProperty|Set-ItemProperty)' -AllowedFileNames @()
Add-Check -Name 'no_registry_alteration_anywhere' -Passed ($registryViolations.Count -eq 0) -Message ($registryViolations -join '; ')

$shellStartupViolations = Find-PatternViolations -Pattern 'shell:startup' -AllowedFileNames @()
Add-Check -Name 'no_shell_startup_folder_reference' -Passed ($shellStartupViolations.Count -eq 0) -Message ($shellStartupViolations -join '; ')

$autoElevationViolations = Find-PatternViolations -Pattern '-Verb\s+[''"]?RunAs' -AllowedFileNames @()
Add-Check -Name 'no_autoelevation_via_verb_runas' -Passed ($autoElevationViolations.Count -eq 0) -Message ($autoElevationViolations -join '; ')

$forceFlagViolations = Find-PatternViolations -Pattern '--force\b' -AllowedFileNames @()
Add-Check -Name 'no_hardcoded_force_flag_usage' -Passed ($forceFlagViolations.Count -eq 0) -Message ($forceFlagViolations -join '; ')

$processSpawningAllowedFiles = @('command_runner.ps1', 'launcher_common.ps1', 'launcher_fallback_windows.ps1', 'launcher_grid_2x2.ps1', 'launcher_startup_safe.ps1', 'launcher_maintenance_real.ps1')
$processSpawningViolations = Find-PatternViolations -Pattern '(Start-Process|System\.Diagnostics\.Process)' -AllowedFileNames $processSpawningAllowedFiles
Add-Check -Name 'process_spawning_only_in_known_runner_files' -Passed ($processSpawningViolations.Count -eq 0) -Message ($processSpawningViolations -join '; ')

$knownMaintenanceCommandPatterns = @(
    '(?i)dism(\.exe)?\s+/online\s+/cleanup-image\s+/restorehealth',
    '(?i)sfc(\.exe)?\s+/scannow',
    '(?i)chkdsk(\.exe)?\s+c:\s*/r',
    '(?i)chkdsk(\.exe)?\s+c:\s*/scan',
    '(?i)defrag(\.exe)?\s+c:\s*/o\s*/u\s*/v'
)
$maintenanceCommandAllowedFiles = @('command_runner.ps1', 'maintenance_real_common.ps1', 'terminal_runner.ps1', 'launcher_maintenance_real.ps1')
$maintenanceCommandViolations = @()
foreach ($pattern in $knownMaintenanceCommandPatterns) {
    $maintenanceCommandViolations += Find-PatternViolations -Pattern $pattern -AllowedFileNames $maintenanceCommandAllowedFiles
}
$maintenanceCommandViolations = @($maintenanceCommandViolations | Select-Object -Unique)
Add-Check -Name 'maintenance_commands_only_in_controlled_files' -Passed ($maintenanceCommandViolations.Count -eq 0) -Message ($maintenanceCommandViolations -join '; ')

$finishedAt = Get-Date
$passed = ($script:errors.Count -eq 0)

$result = [ordered]@{
    testName = $testName
    startedAt = $startedAt.ToString('o')
    finishedAt = $finishedAt.ToString('o')
    passed = $passed
    filesScanned = @($scannedFiles | ForEach-Object { $_.FullName })
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
