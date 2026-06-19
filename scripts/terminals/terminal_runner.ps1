$script:WmtgTerminalRunnerDirectory = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $PSScriptRoot
} elseif (-not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    (Get-Location).Path
}

function Get-TerminalProjectRoot {
    [CmdletBinding()]
    param()

    $currentPath = $script:WmtgTerminalRunnerDirectory
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

    throw 'Project root not found for terminal runner.'
}

function Get-TerminalConfigById {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$TerminalsConfig,

        [Parameter(Mandatory = $true)]
        [string]$TerminalId
    )

    $matches = @($TerminalsConfig.terminals | Where-Object { $_.id -eq $TerminalId })
    if ($matches.Count -ne 1) {
        throw "Expected exactly one terminal config for id '$TerminalId', found $($matches.Count)."
    }

    return $matches[0]
}

function Get-TerminalConsoleColor {
    [CmdletBinding()]
    param(
        [string]$TerminalId,
        [object]$TerminalConfig,
        [object]$VisualSettings
    )

    $colorName = $null
    if ($VisualSettings -and $VisualSettings.colors -and $VisualSettings.colors.$TerminalId) {
        $colorName = $VisualSettings.colors.$TerminalId.foreground
    }

    if ([string]::IsNullOrWhiteSpace($colorName) -and $TerminalConfig) {
        $colorName = $TerminalConfig.ansiColor
    }

    if ([string]::IsNullOrWhiteSpace($colorName)) {
        $colorName = 'Gray'
    }

    try {
        return [ConsoleColor]$colorName
    } catch {
        return [ConsoleColor]::Gray
    }
}

function Split-PlannedCommandLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandLine
    )

    $parts = @($CommandLine -split '\s+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($parts.Count -eq 0) {
        throw 'Planned command line is empty.'
    }

    return [PSCustomObject]@{
        Command = $parts[0]
        Arguments = @($parts | Select-Object -Skip 1)
        CommandLine = $CommandLine
    }
}

function Get-TerminalPlannedCommandData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$TerminalConfig
    )

    if ($TerminalConfig.id -eq 'processing') {
        return [PSCustomObject]@{
            Primary = $TerminalConfig.plannedSafeCommand
            Deep = $TerminalConfig.plannedDeepCommand
            DeepRequiresManualConfirmation = [bool]$TerminalConfig.requiresManualConfirmationForDeepCommand
        }
    }

    return [PSCustomObject]@{
        Primary = $TerminalConfig.plannedRealCommand
        Deep = $null
        DeepRequiresManualConfirmation = $false
    }
}

function Get-TerminalDescription {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TerminalId
    )

    switch ($TerminalId) {
        'analytics' { return 'Imagem do Windows: planejamento DISM em dry-run visual.' }
        'scanning' { return 'Arquivos protegidos: planejamento SFC em dry-run visual.' }
        'processing' { return 'Disco: planejamento CHKDSK em dry-run visual.' }
        'cleaning' { return 'Unidade: planejamento de otimizacao em dry-run visual.' }
        default { return 'Terminal visual em dry-run.' }
    }
}

function Start-TerminalRoutine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TerminalId,

        [ValidateSet('visual_only', 'startup_safe', 'maintenance_real', 'maintenance_real_deep')]
        [string]$Mode = 'startup_safe',

        [string]$RunLogDirectory = '',
        [switch]$NoPause,
        [switch]$DryRun
    )

    $projectRoot = Get-TerminalProjectRoot
    $commonPath = Join-Path $projectRoot 'scripts/common/common.ps1'
    . $commonPath

    $terminalsConfig = Get-TerminalsConfig -ProjectRoot $projectRoot
    $visualSettings = Get-VisualSettings -ProjectRoot $projectRoot
    $terminalConfig = Get-TerminalConfigById -TerminalsConfig $terminalsConfig -TerminalId $TerminalId
    $terminalTitle = $terminalConfig.title
    $terminalColor = Get-TerminalConsoleColor -TerminalId $TerminalId -TerminalConfig $terminalConfig -VisualSettings $visualSettings

    if ([string]::IsNullOrWhiteSpace($RunLogDirectory)) {
        $runContext = New-RunContext -ProjectRoot $projectRoot -Mode $Mode -Source $TerminalId -DryRun $true
        $RunLogDirectory = $runContext.LogDirectory
        $runId = $runContext.RunId
    } else {
        $RunLogDirectory = Resolve-WmtgProjectPath -Path $RunLogDirectory -ProjectRoot $projectRoot
        Initialize-RunDirectory -ProjectRoot $projectRoot -RunLogDirectory $RunLogDirectory | Out-Null
        $metadata = Read-RunMetadata -RunLogDirectory $RunLogDirectory -ProjectRoot $projectRoot
        if ($metadata -and $metadata.runId) {
            $runId = $metadata.runId
        } else {
            $runId = Split-Path -Leaf $RunLogDirectory
        }
    }

    $logFile = Join-Path $RunLogDirectory ("terminals/{0}.log" -f $TerminalId)
    $summary = New-ExecutionSummary -Mode $Mode -RunId $runId -ProjectRoot $projectRoot -Source $TerminalId -DryRun $true

    Write-SectionLog -Title "$terminalTitle terminal bootstrap" -Terminal $terminalTitle -LogFile $logFile -ProjectRoot $projectRoot | Out-Null
    Write-ColoredLog -Message 'Safe terminal entry script started. Block 04 enforces dry-run behavior.' -Level 'INFO' -Terminal $terminalTitle -LogFile $logFile -ProjectRoot $projectRoot -Color $terminalColor -Prefix 'STATUS' | Out-Null
    Write-TerminalLog -RunLogDirectory $RunLogDirectory -RunId $runId -TerminalId $TerminalId -Message 'Terminal bootstrap started.' -Level 'INFO' -ProjectRoot $projectRoot | Out-Null

    Show-TerminalIntro -Title $terminalTitle -Description (Get-TerminalDescription -TerminalId $TerminalId) -Color $terminalColor -TypingDelayMilliseconds 0 -LogFile $logFile -ProjectRoot $projectRoot
    Show-LoadingBar -Activity "$terminalTitle visual initialization" -DurationSeconds 0 -Color $terminalColor -LogFile $logFile -ProjectRoot $projectRoot -Terminal $terminalTitle
    Show-Spinner -Message "$terminalTitle dry-run preparation" -DurationSeconds 0 -Color $terminalColor -LogFile $logFile -ProjectRoot $projectRoot -Terminal $terminalTitle

    $effectiveDryRun = $true
    if (-not $DryRun.IsPresent) {
        Write-WarningLog -Message 'DryRun parameter was not supplied; dry-run remains forced by Block 04.' -Terminal $terminalTitle -LogFile $logFile -ProjectRoot $projectRoot | Out-Null
    }

    if ($Mode -eq 'startup_safe' -or $Mode -eq 'visual_only') {
        Write-ColoredLog -Message "Mode '$Mode' is visual-only. No maintenance command will run." -Level 'SUCCESS' -Terminal $terminalTitle -LogFile $logFile -ProjectRoot $projectRoot -Color $terminalColor -Prefix 'VISUAL' | Out-Null
    } elseif ($Mode -eq 'maintenance_real' -or $Mode -eq 'maintenance_real_deep') {
        Write-WarningLog -Message "Mode '$Mode' requested, but allowRealMaintenance is '$($terminalsConfig.allowRealMaintenance)'. Real execution remains blocked." -Terminal $terminalTitle -LogFile $logFile -ProjectRoot $projectRoot | Out-Null
    }

    $planned = Get-TerminalPlannedCommandData -TerminalConfig $terminalConfig
    if (-not [string]::IsNullOrWhiteSpace($planned.Primary)) {
        $commandData = Split-PlannedCommandLine -CommandLine $planned.Primary
        $result = Invoke-DryRunCommand -Command $commandData.Command -Arguments $commandData.Arguments -Terminal $terminalTitle -Mode $Mode -LogPath $logFile -ProjectRoot $projectRoot
        Add-SummaryEntry -Summary $summary -Terminal $terminalTitle -Command $result.command -Arguments $result.arguments -DryRun $effectiveDryRun -Status $result.status -ExitCode $null -ErrorMessage $null -StartedAt $result.startedAt -FinishedAt $result.finishedAt | Out-Null
    }

    if (-not [string]::IsNullOrWhiteSpace($planned.Deep)) {
        Write-WarningLog -Message "Deep command is planned only and requires future manual confirmation: $($planned.Deep)" -Terminal $terminalTitle -LogFile $logFile -ProjectRoot $projectRoot | Out-Null
        Add-SummaryEntry -Summary $summary -Terminal $terminalTitle -Command $planned.Deep -Arguments @() -DryRun $true -Status 'blocked_future_confirmation' -ExitCode $null -ErrorMessage 'Deep command not invoked in Block 04.' | Out-Null
    }

    Write-ColoredLog -Message "$terminalTitle completed in dry-run/visual-only mode. No maintenance was executed." -Level 'SUCCESS' -Terminal $terminalTitle -LogFile $logFile -ProjectRoot $projectRoot -Color $terminalColor -Prefix 'STATUS' | Out-Null
    $summaryPath = Write-TerminalSummaryJson -Summary $summary -RunLogDirectory $RunLogDirectory -TerminalId $TerminalId -ProjectRoot $projectRoot
    Write-ColoredLog -Message "Per-terminal summary written to $summaryPath" -Level 'DEBUG' -Terminal $terminalTitle -LogFile $logFile -ProjectRoot $projectRoot -Color DarkGray -Prefix 'STATUS' | Out-Null
    Write-TerminalLog -RunLogDirectory $RunLogDirectory -RunId $runId -TerminalId $TerminalId -Message "Terminal completed in dry-run mode. Summary: $summaryPath" -Level 'SUCCESS' -ProjectRoot $projectRoot | Out-Null

    if ($terminalsConfig.keepTerminalOpenAfterFinish -and -not $NoPause.IsPresent) {
        Read-Host "Press Enter to close $terminalTitle"
    }

    return [PSCustomObject]@{
        TerminalId = $TerminalId
        Mode = $Mode
        DryRun = $true
        RunId = $runId
        RunLogDirectory = $RunLogDirectory
        LogFile = $logFile
        SummaryFile = $summaryPath
        Status = 'completed_dry_run'
    }
}
