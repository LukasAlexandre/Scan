param(
    [switch]$DryRun,
    [switch]$RunReal,
    [string]$ConfirmationToken = '',
    [switch]$AllowSessionRealMaintenance,
    [switch]$IncludeDiskScan,
    [switch]$IncludeDeepDiskRepair,
    [switch]$UseFallback,
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'

$maintenanceScriptDirectory = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $PSScriptRoot
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}

. (Join-Path $maintenanceScriptDirectory 'maintenance_real_common.ps1')

$projectRoot = Resolve-MaintenanceProjectRoot -StartPath $maintenanceScriptDirectory
. (Join-Path $projectRoot 'scripts/common/common.ps1')

$terminalsConfig = Get-TerminalsConfig -ProjectRoot $projectRoot
$visualSettings = Get-VisualSettings -ProjectRoot $projectRoot
$scheduleSettings = Get-ScheduleSettings -ProjectRoot $projectRoot
$runLogDirectory = New-RunLogDirectory -ProjectRoot $projectRoot -RunId ('maintenance_real_{0}' -f (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'))
$maintenanceLogFile = Join-Path $runLogDirectory 'maintenance_real.log'
$summary = New-ExecutionSummary -Mode 'maintenance_real' -RunId (Split-Path -Leaf $runLogDirectory) -ProjectRoot $projectRoot

Write-SectionLog -Title 'Block 07 maintenance real launcher' -Terminal 'MAINTENANCE' -LogFile $maintenanceLogFile -ProjectRoot $projectRoot | Out-Null
Write-WarningLog -Message 'Manual maintenance launcher started. DryRun remains the default and startup_safe is not used.' -Terminal 'MAINTENANCE' -LogFile $maintenanceLogFile -ProjectRoot $projectRoot | Out-Null
Write-Log -Message "Parameters: DryRun='$($DryRun.IsPresent)', RunReal='$($RunReal.IsPresent)', AllowSessionRealMaintenance='$($AllowSessionRealMaintenance.IsPresent)', IncludeDiskScan='$($IncludeDiskScan.IsPresent)', IncludeDeepDiskRepair='$($IncludeDeepDiskRepair.IsPresent)', UseFallback='$($UseFallback.IsPresent)', NoPause='$($NoPause.IsPresent)'." -Level 'INFO' -Terminal 'MAINTENANCE' -LogFile $maintenanceLogFile -ProjectRoot $projectRoot | Out-Null
Write-Log -Message "Loaded visual settings version '$($visualSettings.version)' for audit context only." -Level 'DEBUG' -Terminal 'MAINTENANCE' -LogFile $maintenanceLogFile -ProjectRoot $projectRoot | Out-Null

if ($UseFallback.IsPresent) {
    Write-WarningLog -Message 'UseFallback is accepted for interface symmetry, but Block 07 uses a controlled sequential queue instead of opening fallback windows.' -Terminal 'MAINTENANCE' -LogFile $maintenanceLogFile -ProjectRoot $projectRoot | Out-Null
}
if ($NoPause.IsPresent) {
    Write-Log -Message 'NoPause received; the controlled queue launcher does not pause interactively.' -Level 'DEBUG' -Terminal 'MAINTENANCE' -LogFile $maintenanceLogFile -ProjectRoot $projectRoot | Out-Null
}

$configSafety = Test-MaintenanceConfigurationSafety -TerminalsConfig $terminalsConfig -ScheduleSettings $scheduleSettings
if (-not $configSafety.IsSafe) {
    foreach ($violation in $configSafety.Violations) {
        Write-ErrorLog -Message $violation -Terminal 'MAINTENANCE' -LogFile $maintenanceLogFile -ProjectRoot $projectRoot | Out-Null
    }

    throw "Maintenance real blocked by unsafe configuration: $($configSafety.Violations -join '; ')"
}

$isAdmin = $false
if ($RunReal.IsPresent -and -not $DryRun.IsPresent) {
    $isAdmin = Test-IsAdmin
}

$gates = Test-MaintenanceRealGates -DryRun:$DryRun -RunReal:$RunReal -ConfirmationToken $ConfirmationToken -AllowSessionRealMaintenance:$AllowSessionRealMaintenance -IsAdmin $isAdmin
$plan = New-MaintenanceExecutionPlan -TerminalsConfig $terminalsConfig -IncludeDiskScan:$IncludeDiskScan -IncludeDeepDiskRepair:$IncludeDeepDiskRepair

foreach ($entry in ($plan | Sort-Object Sequence)) {
    Write-Log -Message "Plan $($entry.Sequence): $($entry.CommandLine) | enabled=$($entry.Enabled) | status=$($entry.Status) | reason=$($entry.Reason)" -Level 'INFO' -Terminal 'MAINTENANCE' -LogFile $maintenanceLogFile -ProjectRoot $projectRoot | Out-Null
}

if (-not $gates.IsApproved) {
    foreach ($violation in $gates.Violations) {
        Write-ErrorLog -Message $violation -Terminal 'MAINTENANCE' -LogFile $maintenanceLogFile -ProjectRoot $projectRoot | Out-Null
        Add-SummaryEntry -Summary $summary -Terminal 'MAINTENANCE' -Command 'RunReal gates' -Arguments @($violation) -DryRun $true -Status 'blocked_gate' -ExitCode $null -ErrorMessage $violation | Out-Null
    }

    $summaryPath = Write-SummaryJson -Summary $summary -RunLogDirectory $runLogDirectory -ProjectRoot $projectRoot
    Write-ErrorLog -Message "RunReal blocked before any maintenance command. Summary: $summaryPath" -Terminal 'MAINTENANCE' -LogFile $maintenanceLogFile -ProjectRoot $projectRoot | Out-Null
    throw "Maintenance real gates were not approved: $($gates.Violations -join '; ')"
}

if ($gates.EffectiveDryRun) {
    Write-WarningLog -Message 'Effective mode is dry-run. No Windows maintenance command will be executed.' -Terminal 'MAINTENANCE' -LogFile $maintenanceLogFile -ProjectRoot $projectRoot | Out-Null
} else {
    Write-WarningLog -Message 'All gates approved for real execution. Commands will run sequentially through Invoke-CommandWithLog.' -Terminal 'MAINTENANCE' -LogFile $maintenanceLogFile -ProjectRoot $projectRoot | Out-Null
}

Invoke-MaintenanceExecutionPlan -Plan $plan -Summary $summary -RunLogDirectory $runLogDirectory -LogFile $maintenanceLogFile -ProjectRoot $projectRoot -DryRun $gates.EffectiveDryRun -ConfirmationToken $ConfirmationToken | Out-Null

$summaryPath = Write-SummaryJson -Summary $summary -RunLogDirectory $runLogDirectory -ProjectRoot $projectRoot
Write-Log -Message "Maintenance launcher completed with EffectiveDryRun='$($gates.EffectiveDryRun)'. Summary: $summaryPath" -Level 'SUCCESS' -Terminal 'MAINTENANCE' -LogFile $maintenanceLogFile -ProjectRoot $projectRoot | Out-Null
Write-Log -Message 'No scheduled task, startup integration, registry change, autoelevation or startup_safe call was performed.' -Level 'SUCCESS' -Terminal 'MAINTENANCE' -LogFile $maintenanceLogFile -ProjectRoot $projectRoot | Out-Null
