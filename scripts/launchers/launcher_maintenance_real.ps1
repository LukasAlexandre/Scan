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

$effectiveDryRunForContext = -not ($RunReal.IsPresent -and -not $DryRun.IsPresent)
$runContext = New-RunContext -ProjectRoot $projectRoot -Mode 'maintenance_real' -Source 'maintenance_real' -DryRun $effectiveDryRunForContext
$runLogDirectory = $runContext.LogDirectory
$maintenanceLogFile = Join-Path $runLogDirectory 'maintenance_real.log'
$summary = New-ExecutionSummary -Mode 'maintenance_real' -RunId $runContext.RunId -ProjectRoot $projectRoot -Source 'maintenance_real' -DryRun $effectiveDryRunForContext

Write-SectionLog -Title 'Block 09 maintenance real launcher' -Terminal 'MAINTENANCE' -LogFile $maintenanceLogFile -ProjectRoot $projectRoot | Out-Null
Write-MaintenanceLog -RunLogDirectory $runLogDirectory -RunId $runContext.RunId -Message 'Manual maintenance launcher started. DryRun remains the default and startup_safe is not used.' -Level 'WARN' -ProjectRoot $projectRoot | Out-Null
Write-MaintenanceLog -RunLogDirectory $runLogDirectory -RunId $runContext.RunId -Message "Parameters: DryRun='$($DryRun.IsPresent)', RunReal='$($RunReal.IsPresent)', AllowSessionRealMaintenance='$($AllowSessionRealMaintenance.IsPresent)', IncludeDiskScan='$($IncludeDiskScan.IsPresent)', IncludeDeepDiskRepair='$($IncludeDeepDiskRepair.IsPresent)', UseFallback='$($UseFallback.IsPresent)', NoPause='$($NoPause.IsPresent)'." -Level 'INFO' -ProjectRoot $projectRoot | Out-Null
Write-MaintenanceLog -RunLogDirectory $runLogDirectory -RunId $runContext.RunId -Message "Loaded visual settings version '$($visualSettings.version)' for audit context only." -Level 'DEBUG' -ProjectRoot $projectRoot | Out-Null

if ($UseFallback.IsPresent) {
    Write-MaintenanceLog -RunLogDirectory $runLogDirectory -RunId $runContext.RunId -Message 'UseFallback is accepted for interface symmetry, but Block 07/09 use a controlled sequential queue instead of opening fallback windows.' -Level 'WARN' -ProjectRoot $projectRoot | Out-Null
}
if ($NoPause.IsPresent) {
    Write-MaintenanceLog -RunLogDirectory $runLogDirectory -RunId $runContext.RunId -Message 'NoPause received; the controlled queue launcher does not pause interactively.' -Level 'DEBUG' -ProjectRoot $projectRoot | Out-Null
}

$lockStatus = $null

try {
    $lockStatus = New-LockFile -Mode 'maintenance_real' -RunId $runContext.RunId -ProjectRoot $projectRoot -LogDirectory $runLogDirectory -ExpiresAfterMinutes 180
    Write-MaintenanceLog -RunLogDirectory $runLogDirectory -RunId $runContext.RunId -Message "Run lock acquired at $($lockStatus.Path)." -Level 'INFO' -ProjectRoot $projectRoot | Out-Null

    $configSafety = Test-MaintenanceConfigurationSafety -TerminalsConfig $terminalsConfig -ScheduleSettings $scheduleSettings
    if (-not $configSafety.IsSafe) {
        foreach ($violation in $configSafety.Violations) {
            Write-MaintenanceLog -RunLogDirectory $runLogDirectory -RunId $runContext.RunId -Message $violation -Level 'ERROR' -ProjectRoot $projectRoot | Out-Null
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
        Write-MaintenanceLog -RunLogDirectory $runLogDirectory -RunId $runContext.RunId -Message "Plan $($entry.Sequence): $($entry.CommandLine) | enabled=$($entry.Enabled) | status=$($entry.Status) | reason=$($entry.Reason)" -Level 'INFO' -ProjectRoot $projectRoot | Out-Null
    }

    if (-not $gates.IsApproved) {
        foreach ($violation in $gates.Violations) {
            Write-MaintenanceLog -RunLogDirectory $runLogDirectory -RunId $runContext.RunId -Message $violation -Level 'ERROR' -ProjectRoot $projectRoot | Out-Null
            Add-SummaryEntry -Summary $summary -Terminal 'MAINTENANCE' -Command 'RunReal gates' -Arguments @($violation) -DryRun $true -Status 'blocked_gate' -ExitCode $null -ErrorMessage $violation | Out-Null
        }

        $summaryPath = Write-ConsolidatedSummaryJson -Summary $summary -RunLogDirectory $runLogDirectory -Source 'maintenance_real' -ProjectRoot $projectRoot
        Write-MaintenanceLog -RunLogDirectory $runLogDirectory -RunId $runContext.RunId -Message "RunReal blocked before any maintenance command. Summary: $summaryPath" -Level 'ERROR' -ProjectRoot $projectRoot | Out-Null
        throw "Maintenance real gates were not approved: $($gates.Violations -join '; ')"
    }

    if ($gates.EffectiveDryRun) {
        Write-MaintenanceLog -RunLogDirectory $runLogDirectory -RunId $runContext.RunId -Message 'Effective mode is dry-run. No Windows maintenance command will be executed.' -Level 'WARN' -ProjectRoot $projectRoot | Out-Null
    } else {
        Write-MaintenanceLog -RunLogDirectory $runLogDirectory -RunId $runContext.RunId -Message 'All gates approved for real execution. Commands will run sequentially through Invoke-CommandWithLog.' -Level 'WARN' -ProjectRoot $projectRoot | Out-Null
    }

    Invoke-MaintenanceExecutionPlan -Plan $plan -Summary $summary -RunLogDirectory $runLogDirectory -LogFile $maintenanceLogFile -ProjectRoot $projectRoot -DryRun $gates.EffectiveDryRun -ConfirmationToken $ConfirmationToken | Out-Null

    $summaryPath = Write-ConsolidatedSummaryJson -Summary $summary -RunLogDirectory $runLogDirectory -Source 'maintenance_real' -ProjectRoot $projectRoot
    Write-MaintenanceLog -RunLogDirectory $runLogDirectory -RunId $runContext.RunId -Message "Maintenance launcher completed with EffectiveDryRun='$($gates.EffectiveDryRun)'. Summary: $summaryPath" -Level 'SUCCESS' -ProjectRoot $projectRoot | Out-Null
    Write-MaintenanceLog -RunLogDirectory $runLogDirectory -RunId $runContext.RunId -Message 'No scheduled task, startup integration, registry change, autoelevation or startup_safe call was performed.' -Level 'SUCCESS' -ProjectRoot $projectRoot | Out-Null
} finally {
    if ($lockStatus -and $lockStatus.Exists -and $lockStatus.Pid -eq $PID) {
        Remove-LockFile -ExpectedPid $PID | Out-Null
        Write-MaintenanceLog -RunLogDirectory $runLogDirectory -RunId $runContext.RunId -Message 'Run lock released by maintenance launcher before exit.' -Level 'INFO' -ProjectRoot $projectRoot | Out-Null
    }
}
