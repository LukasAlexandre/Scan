$script:WmtgMaintenanceDirectory = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $PSScriptRoot
} elseif (-not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    (Get-Location).Path
}

function Resolve-MaintenanceProjectRoot {
    [CmdletBinding()]
    param(
        [string]$StartPath
    )

    if ([string]::IsNullOrWhiteSpace($StartPath)) {
        $StartPath = $script:WmtgMaintenanceDirectory
    }

    if (-not (Test-Path -LiteralPath $StartPath)) {
        throw "Maintenance start path not found: $StartPath"
    }

    $currentPath = (Resolve-Path -LiteralPath $StartPath).Path
    $item = Get-Item -LiteralPath $currentPath
    if (-not $item.PSIsContainer) {
        $currentPath = Split-Path -Parent $currentPath
    }

    while (-not [string]::IsNullOrWhiteSpace($currentPath)) {
        if ((Test-Path -LiteralPath (Join-Path $currentPath 'config')) -and
            (Test-Path -LiteralPath (Join-Path $currentPath 'scripts/common/common.ps1'))) {
            return $currentPath
        }

        $parent = Split-Path -Parent $currentPath
        if ($parent -eq $currentPath) {
            break
        }

        $currentPath = $parent
    }

    throw "Project root not found from maintenance path: $StartPath"
}

function Split-MaintenanceCommandLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandLine
    )

    $parts = @($CommandLine -split '\s+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($parts.Count -eq 0) {
        throw 'Maintenance command line is empty.'
    }

    return [PSCustomObject]@{
        Command = $parts[0]
        Arguments = @($parts | Select-Object -Skip 1)
        CommandLine = $CommandLine
    }
}

function Get-MaintenanceTerminalConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$TerminalsConfig,

        [Parameter(Mandatory = $true)]
        [string]$TerminalId
    )

    $matches = @($TerminalsConfig.terminals | Where-Object { $_.id -eq $TerminalId })
    if ($matches.Count -ne 1) {
        throw "Expected exactly one terminal config for '$TerminalId', found $($matches.Count)."
    }

    return $matches[0]
}

function New-MaintenancePlanEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$Sequence,

        [Parameter(Mandatory = $true)]
        [string]$TerminalId,

        [Parameter(Mandatory = $true)]
        [string]$TerminalTitle,

        [Parameter(Mandatory = $true)]
        [string]$CommandLine,

        [bool]$Enabled = $true,
        [string]$Status = 'planned',
        [string]$Reason = '',
        [bool]$RequiresAdmin = $true,
        [bool]$RequiresConfirmation = $true,
        [bool]$IsDeepDiskRepair = $false
    )

    $commandData = Split-MaintenanceCommandLine -CommandLine $CommandLine

    return [PSCustomObject]@{
        Sequence = $Sequence
        TerminalId = $TerminalId
        TerminalTitle = $TerminalTitle
        Command = $commandData.Command
        Arguments = $commandData.Arguments
        CommandLine = $commandData.CommandLine
        Enabled = $Enabled
        Status = $Status
        Reason = $Reason
        RequiresAdmin = $RequiresAdmin
        RequiresConfirmation = $RequiresConfirmation
        IsDeepDiskRepair = $IsDeepDiskRepair
    }
}

function New-MaintenanceExecutionPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$TerminalsConfig,

        [switch]$IncludeDiskScan,
        [switch]$IncludeDeepDiskRepair
    )

    $analytics = Get-MaintenanceTerminalConfig -TerminalsConfig $TerminalsConfig -TerminalId 'analytics'
    $scanning = Get-MaintenanceTerminalConfig -TerminalsConfig $TerminalsConfig -TerminalId 'scanning'
    $processing = Get-MaintenanceTerminalConfig -TerminalsConfig $TerminalsConfig -TerminalId 'processing'
    $cleaning = Get-MaintenanceTerminalConfig -TerminalsConfig $TerminalsConfig -TerminalId 'cleaning'

    $plan = @(
        New-MaintenancePlanEntry -Sequence 1 -TerminalId $analytics.id -TerminalTitle $analytics.title -CommandLine $analytics.plannedRealCommand -Reason 'DISM image maintenance planned for controlled manual execution.'
        New-MaintenancePlanEntry -Sequence 2 -TerminalId $scanning.id -TerminalTitle $scanning.title -CommandLine $scanning.plannedRealCommand -Reason 'SFC protected file verification planned after DISM.'
        New-MaintenancePlanEntry -Sequence 3 -TerminalId $processing.id -TerminalTitle $processing.title -CommandLine $processing.plannedSafeCommand -Enabled:$IncludeDiskScan.IsPresent -Status $(if ($IncludeDiskScan.IsPresent) { 'planned' } else { 'skipped_not_requested' }) -Reason $(if ($IncludeDiskScan.IsPresent) { 'Optional CHKDSK online scan requested.' } else { 'Optional CHKDSK online scan not requested.' })
        New-MaintenancePlanEntry -Sequence 4 -TerminalId $cleaning.id -TerminalTitle $cleaning.title -CommandLine $cleaning.plannedRealCommand -Reason 'Optimize/defrag is heavy and remains last in the controlled queue.'
        New-MaintenancePlanEntry -Sequence 5 -TerminalId $processing.id -TerminalTitle $processing.title -CommandLine $processing.plannedDeepCommand -Enabled:$false -Status 'blocked_deep_disk_repair' -Reason $(if ($IncludeDeepDiskRepair.IsPresent) { 'Deep disk repair was requested but remains blocked in Block 07.' } else { 'Deep disk repair is blocked by default.' }) -IsDeepDiskRepair $true
    )

    return @($plan)
}

function Test-MaintenanceConfigurationSafety {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$TerminalsConfig,

        [Parameter(Mandatory = $true)]
        [object]$ScheduleSettings
    )

    $violations = @()

    if ([bool]$ScheduleSettings.startup.enabled) {
        $violations += 'startup.enabled must remain false.'
    }
    if ([bool]$ScheduleSettings.scheduledTask.autoCreate) {
        $violations += 'scheduledTask.autoCreate must remain false.'
    }
    if ([bool]$ScheduleSettings.startup.allowHeavyCommandsOnStartup) {
        $violations += 'startup.allowHeavyCommandsOnStartup must remain false.'
    }
    if ([bool]$TerminalsConfig.allowStartupHeavyCommands) {
        $violations += 'allowStartupHeavyCommands must remain false.'
    }

    return [PSCustomObject]@{
        IsSafe = ($violations.Count -eq 0)
        Violations = $violations
    }
}

function Test-MaintenanceRealGates {
    [CmdletBinding()]
    param(
        [switch]$DryRun,
        [switch]$RunReal,
        [string]$ConfirmationToken = '',
        [switch]$AllowSessionRealMaintenance,
        [bool]$IsAdmin = $false
    )

    $effectiveDryRun = ($DryRun.IsPresent -or -not $RunReal.IsPresent)
    $violations = @()

    if (-not $effectiveDryRun) {
        if (-not $IsAdmin) {
            $violations += 'Administrator privileges are required for RunReal.'
        }
        if (-not $AllowSessionRealMaintenance.IsPresent) {
            $violations += 'AllowSessionRealMaintenance is required for RunReal.'
        }
        if ($ConfirmationToken -ne 'I_ACCEPT_WINDOWS_MAINTENANCE') {
            $violations += 'ConfirmationToken must be I_ACCEPT_WINDOWS_MAINTENANCE for RunReal.'
        }
    }

    return [PSCustomObject]@{
        EffectiveDryRun = $effectiveDryRun
        RunRealRequested = $RunReal.IsPresent
        IsApproved = ($violations.Count -eq 0)
        Violations = $violations
    }
}

function Invoke-MaintenanceExecutionPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Plan,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Summary,

        [Parameter(Mandatory = $true)]
        [string]$RunLogDirectory,

        [Parameter(Mandatory = $true)]
        [string]$LogFile,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [bool]$DryRun = $true,
        [string]$ConfirmationToken = ''
    )

    foreach ($entry in ($Plan | Sort-Object Sequence)) {
        if (-not $entry.Enabled) {
            Write-WarningLog -Message "Skipping $($entry.CommandLine): $($entry.Reason)" -Terminal 'MAINTENANCE' -LogFile $LogFile -ProjectRoot $ProjectRoot | Out-Null
            Add-SummaryEntry -Summary $Summary -Terminal $entry.TerminalTitle -Command $entry.Command -Arguments $entry.Arguments -DryRun $true -Status $entry.Status -ExitCode $null -ErrorMessage $entry.Reason | Out-Null
            continue
        }

        if ($DryRun) {
            $result = Invoke-DryRunCommand -Command $entry.Command -Arguments $entry.Arguments -Terminal $entry.TerminalTitle -Mode 'maintenance_real' -LogPath $LogFile -ProjectRoot $ProjectRoot
        } else {
            $result = Invoke-CommandWithLog -Command $entry.Command -Arguments $entry.Arguments -Terminal $entry.TerminalTitle -Mode 'maintenance_real' -LogPath $LogFile -ProjectRoot $ProjectRoot -DryRun:$false -AllowRealMaintenance:$false -AllowSessionRealMaintenance:$true -RequireAdmin:$entry.RequiresAdmin -RequireExplicitConfirmation:$entry.RequiresConfirmation -ConfirmationToken $ConfirmationToken -RequiredConfirmationToken 'I_ACCEPT_WINDOWS_MAINTENANCE' -AllowedExecutables @('DISM', 'DISM.exe', 'sfc', 'sfc.exe', 'chkdsk', 'chkdsk.exe', 'defrag', 'defrag.exe') -AllowKnownMaintenanceCommand
        }

        Add-SummaryEntry -Summary $Summary -Terminal $entry.TerminalTitle -Command $result.command -Arguments $result.arguments -DryRun ([bool]$result.dryRun) -Status $result.status -ExitCode $result.exitCode -ErrorMessage $result.error -StartedAt $result.startedAt -FinishedAt $result.finishedAt | Out-Null
    }

    return $Summary
}
