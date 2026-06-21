$script:WmtgLauncherDirectory = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $PSScriptRoot
} elseif (-not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    (Get-Location).Path
}

function Resolve-LauncherProjectRoot {
    [CmdletBinding()]
    param(
        [string]$StartPath
    )

    if ([string]::IsNullOrWhiteSpace($StartPath)) {
        $StartPath = $script:WmtgLauncherDirectory
    }

    if (-not (Test-Path -LiteralPath $StartPath)) {
        throw "Launcher start path not found: $StartPath"
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

    throw "Project root not found from launcher path: $StartPath"
}

function Normalize-LauncherMode {
    [CmdletBinding()]
    param(
        [string]$Mode = 'startup_safe'
    )

    if ([string]::IsNullOrWhiteSpace($Mode)) {
        $Mode = 'startup_safe'
    }

    $allowedModes = @('visual_only', 'startup_safe', 'maintenance_real', 'maintenance_real_deep')
    if ($allowedModes -notcontains $Mode) {
        throw "Unsupported launcher mode '$Mode'. Allowed modes: $($allowedModes -join ', ')."
    }

    return $Mode
}

function Assert-LauncherModeAllowedForBlock05 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Mode,

        [string]$LogFile,
        [string]$ProjectRoot
    )

    if ($Mode -eq 'maintenance_real' -or $Mode -eq 'maintenance_real_deep') {
        $message = "Mode '$Mode' is not released in Block 05. Launcher grid remains dry-run/startup-safe only."
        if (Get-Command -Name Write-ErrorLog -ErrorAction SilentlyContinue) {
            Write-ErrorLog -Message $message -Terminal 'LAUNCHER' -LogFile $LogFile -ProjectRoot $ProjectRoot | Out-Null
        }

        throw $message
    }
}

function Test-WindowsTerminalAvailable {
    [CmdletBinding()]
    param()

    return [bool](Get-Command -Name 'wt.exe' -CommandType Application -ErrorAction SilentlyContinue)
}

function Get-WindowsTerminalCommand {
    [CmdletBinding()]
    param()

    return Get-Command -Name 'wt.exe' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
}

function ConvertTo-LauncherArgumentText {
    [CmdletBinding()]
    param(
        [string[]]$Arguments = @()
    )

    $quoted = foreach ($argument in $Arguments) {
        if ($null -eq $argument) {
            continue
        }

        if ($argument -match '[\s"]') {
            '"' + ($argument -replace '"', '\"') + '"'
        } else {
            $argument
        }
    }

    return ($quoted -join ' ')
}

function Resolve-LauncherProjectPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    if (Get-Command -Name Resolve-WmtgProjectPath -ErrorAction SilentlyContinue) {
        return Resolve-WmtgProjectPath -Path $Path -ProjectRoot $ProjectRoot
    }

    $resolvedRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
    if ([System.IO.Path]::IsPathRooted($Path)) {
        $candidate = $Path
    } else {
        $candidate = Join-Path $resolvedRoot $Path
    }

    $fullPath = [System.IO.Path]::GetFullPath($candidate)
    if (-not $fullPath.StartsWith($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to use path outside project root: $fullPath"
    }

    return $fullPath
}

function New-LauncherContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [string]$Mode = 'startup_safe',
        [string]$RunLogDirectory,
        [string]$Source = 'launcher',
        [bool]$DryRun = $true
    )

    $terminalsConfig = Get-TerminalsConfig -ProjectRoot $ProjectRoot
    $visualSettings = Get-VisualSettings -ProjectRoot $ProjectRoot
    $scheduleSettings = Get-ScheduleSettings -ProjectRoot $ProjectRoot

    if ([string]::IsNullOrWhiteSpace($RunLogDirectory)) {
        $runContext = New-RunContext -ProjectRoot $ProjectRoot -Mode $Mode -Source $Source -DryRun $DryRun
    } else {
        $resolvedRunLogDirectory = Resolve-LauncherProjectPath -Path $RunLogDirectory -ProjectRoot $ProjectRoot
        Initialize-RunDirectory -ProjectRoot $ProjectRoot -RunLogDirectory $resolvedRunLogDirectory | Out-Null
        $metadata = Read-RunMetadata -RunLogDirectory $resolvedRunLogDirectory -ProjectRoot $ProjectRoot
        if ($metadata -and $metadata.runId) {
            $runId = $metadata.runId
            $startedAt = $metadata.startedAt
        } else {
            $runId = Split-Path -Leaf $resolvedRunLogDirectory
            $startedAt = (Get-Date).ToString('o')
        }

        $runContext = [PSCustomObject]@{
            RunId = $runId
            Mode = $Mode
            Source = $Source
            DryRun = $DryRun
            ProjectRoot = $ProjectRoot
            LogDirectory = $resolvedRunLogDirectory
            StartedAt = $startedAt
        }
    }

    return [PSCustomObject]@{
        ProjectRoot = $ProjectRoot
        Mode = $Mode
        TerminalsConfig = $terminalsConfig
        VisualSettings = $visualSettings
        ScheduleSettings = $scheduleSettings
        RunLogDirectory = $runContext.LogDirectory
        RunId = $runContext.RunId
        RunContext = $runContext
        LauncherLogFile = Join-Path $runContext.LogDirectory 'launcher.log'
    }
}

function New-LauncherRunLock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Context,

        [int]$MaxAgeMinutes = 180
    )

    Assert-NoActiveLock -MaxAgeMinutes $MaxAgeMinutes | Out-Null
    return New-LockFile -Mode $Context.Mode -RunId $Context.RunId -ProjectRoot $Context.ProjectRoot -LogDirectory $Context.RunLogDirectory -ExpiresAfterMinutes $MaxAgeMinutes
}

function Remove-LauncherRunLock {
    [CmdletBinding()]
    param(
        [object]$LockStatus
    )

    if ($LockStatus -and $LockStatus.Exists -and $LockStatus.Pid -eq $PID) {
        Remove-LockFile -ExpectedPid $PID | Out-Null
        return $true
    }

    return $false
}

function Invoke-LauncherSummaryConsolidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Context,

        [string]$Source = 'launcher'
    )

    $summary = New-ExecutionSummary -Mode $Context.Mode -RunId $Context.RunId -ProjectRoot $Context.ProjectRoot -Source $Source -DryRun $true
    $summaryPath = Write-ConsolidatedSummaryJson -Summary $summary -RunLogDirectory $Context.RunLogDirectory -Source $Source -ProjectRoot $Context.ProjectRoot

    Write-LauncherLog -RunLogDirectory $Context.RunLogDirectory -RunId $Context.RunId -Message "Consolidated summary written to $summaryPath" -Level 'INFO' -ProjectRoot $Context.ProjectRoot | Out-Null

    return $summaryPath
}

function Test-LauncherSafetyFlags {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$TerminalsConfig,

        [Parameter(Mandatory = $true)]
        [object]$ScheduleSettings
    )

    $violations = @()

    if ([bool]$TerminalsConfig.allowRealMaintenance) {
        $violations += 'allowRealMaintenance must remain false.'
    }
    if ([bool]$TerminalsConfig.allowStartupHeavyCommands) {
        $violations += 'allowStartupHeavyCommands must remain false.'
    }
    if ([bool]$ScheduleSettings.startup.allowHeavyCommandsOnStartup) {
        $violations += 'startup.allowHeavyCommandsOnStartup must remain false.'
    }
    if ([bool]$ScheduleSettings.startup.enabled) {
        $violations += 'startup.enabled must remain false in Block 05.'
    }
    if ([bool]$ScheduleSettings.scheduledTask.autoCreate) {
        $violations += 'scheduledTask.autoCreate must remain false.'
    }

    return [PSCustomObject]@{
        IsSafe = ($violations.Count -eq 0)
        Violations = $violations
    }
}

function Get-LauncherTerminalDefinitions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$TerminalsConfig,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $terminalOrder = @('analytics', 'scanning', 'processing', 'cleaning')
    $definitions = foreach ($terminalId in $terminalOrder) {
        $matches = @($TerminalsConfig.terminals | Where-Object { $_.id -eq $terminalId })
        if ($matches.Count -ne 1) {
            throw "Expected exactly one terminal config for '$terminalId', found $($matches.Count)."
        }

        $terminal = $matches[0]
        $fullScriptPath = Resolve-LauncherProjectPath -Path $terminal.scriptPath -ProjectRoot $ProjectRoot

        [PSCustomObject]@{
            Id = $terminal.id
            Title = $terminal.title
            ScriptPath = $terminal.scriptPath
            FullScriptPath = $fullScriptPath
        }
    }

    return @($definitions)
}

function Assert-LauncherTerminalScripts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$TerminalDefinitions
    )

    $missing = @($TerminalDefinitions | Where-Object { -not (Test-Path -LiteralPath $_.FullScriptPath) })
    if ($missing.Count -gt 0) {
        $missingList = ($missing | ForEach-Object { $_.FullScriptPath }) -join ', '
        throw "Terminal script(s) not found: $missingList"
    }
}

function Build-TerminalCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$TerminalDefinition,

        [string]$Mode = 'startup_safe',

        [Parameter(Mandatory = $true)]
        [string]$RunLogDirectory,

        [switch]$NoPause
    )

    $arguments = @(
        '-NoExit',
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        $TerminalDefinition.FullScriptPath,
        '-Mode',
        $Mode,
        '-RunLogDirectory',
        $RunLogDirectory,
        '-DryRun'
    )

    if ($NoPause.IsPresent) {
        $arguments += '-NoPause'
    }

    return [PSCustomObject]@{
        Id = $TerminalDefinition.Id
        Title = $TerminalDefinition.Title
        ScriptPath = $TerminalDefinition.FullScriptPath
        Executable = 'powershell.exe'
        ArgumentList = @($arguments)
        ArgumentText = ConvertTo-LauncherArgumentText -Arguments $arguments
        DryRun = $true
        Mode = $Mode
    }
}

function New-LauncherTerminalCommands {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$TerminalDefinitions,

        [string]$Mode = 'startup_safe',

        [Parameter(Mandatory = $true)]
        [string]$RunLogDirectory,

        [switch]$NoPause
    )

    return @(
        foreach ($definition in $TerminalDefinitions) {
            Build-TerminalCommand -TerminalDefinition $definition -Mode $Mode -RunLogDirectory $RunLogDirectory -NoPause:$NoPause
        }
    )
}

function Add-WindowsTerminalPaneArguments {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$ArgumentList,

        [Parameter(Mandatory = $true)]
        [string]$Action,

        [string]$SplitDirection,
        [string]$SplitSize,

        [Parameter(Mandatory = $true)]
        [object]$TerminalCommand,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    [void]$ArgumentList.Add($Action)
    if (-not [string]::IsNullOrWhiteSpace($SplitDirection)) {
        [void]$ArgumentList.Add($SplitDirection)
    }
    if ($Action -eq 'split-pane' -and -not [string]::IsNullOrWhiteSpace($SplitSize)) {
        [void]$ArgumentList.Add('--size')
        [void]$ArgumentList.Add($SplitSize)
    }

    [void]$ArgumentList.Add('--title')
    [void]$ArgumentList.Add($TerminalCommand.Title)
    [void]$ArgumentList.Add('--suppressApplicationTitle')
    [void]$ArgumentList.Add('--startingDirectory')
    [void]$ArgumentList.Add($ProjectRoot)
    [void]$ArgumentList.Add($TerminalCommand.Executable)

    foreach ($argument in $TerminalCommand.ArgumentList) {
        [void]$ArgumentList.Add($argument)
    }
}

function Get-LauncherTerminalCommandsById {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$TerminalCommands
    )

    if ($TerminalCommands.Count -ne 4) {
        throw "Windows Terminal grid requires exactly 4 terminal commands; received $($TerminalCommands.Count)."
    }

    $commandsById = @{}
    foreach ($command in $TerminalCommands) {
        $commandsById[$command.Id] = $command
    }

    foreach ($requiredId in @('analytics', 'scanning', 'processing', 'cleaning')) {
        if (-not $commandsById.ContainsKey($requiredId)) {
            throw "Windows Terminal grid is missing required terminal command '$requiredId'."
        }
    }

    return $commandsById
}

function Build-WindowsTerminalBootstrapArgumentList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$TerminalCommands,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $commandsById = Get-LauncherTerminalCommandsById -TerminalCommands $TerminalCommands

    $arguments = New-Object 'System.Collections.Generic.List[string]'

    [void]$arguments.Add('--window')
    [void]$arguments.Add('new')

    # top-left: ANALYTICS, the only pane and starting focus point.
    Add-WindowsTerminalPaneArguments -ArgumentList $arguments -Action 'new-tab' -TerminalCommand $commandsById['analytics'] -ProjectRoot $ProjectRoot

    return @($arguments.ToArray())
}

function Build-WindowsTerminalGridCompletionArgumentList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$TerminalCommands,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $commandsById = Get-LauncherTerminalCommandsById -TerminalCommands $TerminalCommands

    $arguments = New-Object 'System.Collections.Generic.List[string]'

    # "last" targets the most recently used Windows Terminal window, i.e. the one the bootstrap
    # call just created with "--window new" (and that the caller waited to become ready).
    [void]$arguments.Add('-w')
    [void]$arguments.Add('last')

    # bottom-left: PROCESSING, horizontal split stacks it below ANALYTICS. Focus moves to PROCESSING.
    Add-WindowsTerminalPaneArguments -ArgumentList $arguments -Action 'split-pane' -SplitDirection '-H' -SplitSize '0.5' -TerminalCommand $commandsById['processing'] -ProjectRoot $ProjectRoot
    [void]$arguments.Add(';')

    [void]$arguments.Add('move-focus')
    [void]$arguments.Add('up')
    [void]$arguments.Add(';')

    # top-right: SCANNING, vertical split places it beside ANALYTICS. Focus moves to SCANNING.
    Add-WindowsTerminalPaneArguments -ArgumentList $arguments -Action 'split-pane' -SplitDirection '-V' -SplitSize '0.5' -TerminalCommand $commandsById['scanning'] -ProjectRoot $ProjectRoot
    [void]$arguments.Add(';')

    [void]$arguments.Add('move-focus')
    [void]$arguments.Add('down')
    [void]$arguments.Add(';')

    # bottom-right: CLEANING, vertical split places it beside PROCESSING.
    Add-WindowsTerminalPaneArguments -ArgumentList $arguments -Action 'split-pane' -SplitDirection '-V' -SplitSize '0.5' -TerminalCommand $commandsById['cleaning'] -ProjectRoot $ProjectRoot

    return @($arguments.ToArray())
}

function Get-WindowsTerminalSessionZoomSettings {
    [CmdletBinding()]
    param(
        [object]$VisualSettings
    )

    $enabled = $true
    $steps = 0
    $delayMilliseconds = 500

    if ($VisualSettings -and $VisualSettings.terminalApp) {
        $terminalApp = $VisualSettings.terminalApp
        $propertyNames = @($terminalApp.PSObject.Properties.Name)

        if ($propertyNames -contains 'sessionZoomEnabled') {
            $enabled = [bool]$terminalApp.sessionZoomEnabled
        }

        if ($propertyNames -contains 'sessionZoomOutSteps') {
            $steps = [int]$terminalApp.sessionZoomOutSteps
        }

        if ($propertyNames -contains 'sessionZoomDelayMilliseconds') {
            $delayMilliseconds = [int]$terminalApp.sessionZoomDelayMilliseconds
        }
    }

    $safeSteps = [Math]::Max(0, [Math]::Min($steps, 20))
    $safeDelay = [Math]::Max(0, [Math]::Min($delayMilliseconds, 5000))

    return [PSCustomObject]@{
        Enabled = $enabled
        ZoomOutSteps = $safeSteps
        DelayMilliseconds = $safeDelay
    }
}

function Get-WindowsTerminalSessionZoomSequence {
    [CmdletBinding()]
    param()

    return @(
        [PSCustomObject]@{
            Title = 'ANALYTICS'
            MoveFocusBefore = 'first'
        }
        [PSCustomObject]@{
            Title = 'SCANNING'
            MoveFocusBefore = 'right'
        }
        [PSCustomObject]@{
            Title = 'CLEANING'
            MoveFocusBefore = 'down'
        }
        [PSCustomObject]@{
            Title = 'PROCESSING'
            MoveFocusBefore = 'left'
        }
    )
}

function Set-WindowsTerminalFocusToCleaning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WindowsTerminalPath
    )

    Invoke-WindowsTerminalMoveFocus -WindowsTerminalPath $WindowsTerminalPath -Direction 'right'
}

function Invoke-WindowsTerminalMoveFocus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WindowsTerminalPath,

        [Parameter(Mandatory = $true)]
        [string]$Direction,

        [int]$DelayMilliseconds = 180
    )

    $arguments = ConvertTo-LauncherArgumentText -Arguments @('-w', 'last', 'move-focus', $Direction)
    Start-Process -FilePath $WindowsTerminalPath -ArgumentList $arguments | Out-Null

    $safeDelay = [Math]::Max(0, [Math]::Min($DelayMilliseconds, 1000))
    if ($safeDelay -gt 0) {
        Start-Sleep -Milliseconds $safeDelay
    }
}

function Wait-WindowsTerminalPaneTitleActive {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Shell,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [int]$TimeoutMilliseconds = 1200
    )

    $deadline = (Get-Date).AddMilliseconds([Math]::Max(100, $TimeoutMilliseconds))
    do {
        if ($Shell.AppActivate($Title)) {
            Start-Sleep -Milliseconds 120
            return $true
        }

        Start-Sleep -Milliseconds 80
    } while ((Get-Date) -lt $deadline)

    return $false
}

function Invoke-WindowsTerminalSessionZoomOut {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WindowsTerminalPath,

        [int]$Steps = 0,
        [int]$DelayMilliseconds = 500,
        [string]$LogFile,
        [string]$ProjectRoot
    )

    $safeSteps = [Math]::Max(0, [Math]::Min($Steps, 20))
    if ($safeSteps -le 0) {
        return [PSCustomObject]@{
            Attempted = $false
            Applied = $false
            Steps = 0
            TargetTitle = $null
            Message = 'Session zoom is disabled or set to 0 steps.'
        }
    }

    try {
        $safeDelay = [Math]::Max(0, [Math]::Min($DelayMilliseconds, 5000))
        if ($safeDelay -gt 0) {
            Start-Sleep -Milliseconds $safeDelay
        }

        $shell = New-Object -ComObject WScript.Shell
        $gridReady = Wait-WindowsTerminalPaneTitleActive -Shell $shell -Title 'CLEANING' -TimeoutMilliseconds 5000
        if (-not $gridReady) {
            return [PSCustomObject]@{
                Attempted = $true
                Applied = $false
                Steps = $safeSteps
                TargetTitle = $null
                PaneResults = @()
                Message = 'Could not confirm the CLEANING pane as active before applying pane zoom; grid assembly may still be in progress.'
            }
        }

        $paneResults = @()
        foreach ($pane in Get-WindowsTerminalSessionZoomSequence) {
            if (-not [string]::IsNullOrWhiteSpace($pane.MoveFocusBefore)) {
                Invoke-WindowsTerminalMoveFocus -WindowsTerminalPath $WindowsTerminalPath -Direction $pane.MoveFocusBefore
            }

            $activated = Wait-WindowsTerminalPaneTitleActive -Shell $shell -Title $pane.Title
            if (-not $activated) {
                $paneResults += [PSCustomObject]@{
                    Title = $pane.Title
                    Applied = $false
                    Message = "Could not focus Windows Terminal pane title '$($pane.Title)'."
                }
                continue
            }

            Start-Sleep -Milliseconds 120
            for ($index = 0; $index -lt $safeSteps; $index++) {
                $shell.SendKeys('^-')
                Start-Sleep -Milliseconds 60
            }

            $paneResults += [PSCustomObject]@{
                Title = $pane.Title
                Applied = $true
                Message = "Sent Ctrl+Minus $safeSteps time(s)."
            }
        }

        if (@($paneResults | Where-Object { $_.Applied }).Count -gt 0) {
            try {
                Set-WindowsTerminalFocusToCleaning -WindowsTerminalPath $WindowsTerminalPath
            } catch {
                # Returning focus to CLEANING is cosmetic; the zoom result above is what matters.
            }
        }

        $failedPanes = @($paneResults | Where-Object { -not $_.Applied })
        return [PSCustomObject]@{
            Attempted = $true
            Applied = ($failedPanes.Count -eq 0)
            Steps = $safeSteps
            TargetTitle = (($paneResults | Where-Object { $_.Applied } | ForEach-Object { $_.Title }) -join ', ')
            PaneResults = $paneResults
            Message = if ($failedPanes.Count -eq 0) {
                "Sent Ctrl+Minus $safeSteps time(s) to all Windows Terminal panes."
            } else {
                "Zoom was not applied to: $((($failedPanes | ForEach-Object { $_.Title }) -join ', '))."
            }
        }
    } catch {
        return [PSCustomObject]@{
            Attempted = $true
            Applied = $false
            Steps = $safeSteps
            TargetTitle = $null
            Message = $_.Exception.Message
        }
    }
}

function Wait-ForWindowsTerminalReady {
    [CmdletBinding()]
    param(
        [int[]]$ExistingProcessIds = @(),
        [int]$ColdStartTimeoutSeconds = 5,
        [int]$WarmStartDelayMilliseconds = 700
    )

    if ($ExistingProcessIds.Count -eq 0) {
        # Cold start: no WindowsTerminal.exe process existed yet, so the app has to be activated
        # from scratch. Poll for the new process (with a real window handle) instead of guessing a delay.
        $deadline = (Get-Date).AddSeconds($ColdStartTimeoutSeconds)
        do {
            $newWindow = Get-Process -Name 'WindowsTerminal' -ErrorAction SilentlyContinue |
                Where-Object { $_.MainWindowHandle -ne 0 } |
                Select-Object -First 1

            if ($newWindow) {
                # Grace buffer: a window handle existing does not guarantee the pane tree and
                # focus state have finished settling yet.
                Start-Sleep -Milliseconds 300
                return $true
            }

            Start-Sleep -Milliseconds 150
        } while ((Get-Date) -lt $deadline)

        return $false
    }

    # Warm start: Windows Terminal already runs as a single-instance app (monarch/peasant model), so
    # opening another window does not spawn a new process to poll for - it is created inside an
    # already-loaded instance. A short fixed delay is enough for the new window to settle.
    Start-Sleep -Milliseconds $WarmStartDelayMilliseconds
    return $true
}

function Start-TerminalGrid {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$TerminalCommands,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [object]$VisualSettings,

        [string]$LogFile
    )

    $wtCommand = Get-WindowsTerminalCommand
    if (-not $wtCommand) {
        throw 'wt.exe was not found.'
    }

    $bootstrapArguments = Build-WindowsTerminalBootstrapArgumentList -TerminalCommands $TerminalCommands -ProjectRoot $ProjectRoot
    $bootstrapArgumentText = ConvertTo-LauncherArgumentText -Arguments $bootstrapArguments

    $completionArguments = Build-WindowsTerminalGridCompletionArgumentList -TerminalCommands $TerminalCommands -ProjectRoot $ProjectRoot
    $completionArgumentText = ConvertTo-LauncherArgumentText -Arguments $completionArguments

    Write-Log -Message 'Starting Windows Terminal grid using wt.exe (two-step bootstrap to avoid a cold-start focus race).' -Level 'INFO' -Terminal 'LAUNCHER' -LogFile $LogFile -ProjectRoot $ProjectRoot | Out-Null
    Write-Log -Message "Windows Terminal bootstrap arguments: $bootstrapArgumentText" -Level 'DEBUG' -Terminal 'LAUNCHER' -LogFile $LogFile -ProjectRoot $ProjectRoot | Out-Null

    $existingProcessIds = @(Get-Process -Name 'WindowsTerminal' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)

    Start-Process -FilePath $wtCommand.Source -ArgumentList $bootstrapArgumentText -WorkingDirectory $ProjectRoot | Out-Null

    $windowReady = Wait-ForWindowsTerminalReady -ExistingProcessIds $existingProcessIds
    if (-not $windowReady) {
        Write-WarningLog -Message 'Timed out waiting for the new WindowsTerminal window to report itself ready; continuing with pane assembly anyway.' -Terminal 'LAUNCHER' -LogFile $LogFile -ProjectRoot $ProjectRoot | Out-Null
    }

    Write-Log -Message "Windows Terminal grid-completion arguments: $completionArgumentText" -Level 'DEBUG' -Terminal 'LAUNCHER' -LogFile $LogFile -ProjectRoot $ProjectRoot | Out-Null
    Start-Process -FilePath $wtCommand.Source -ArgumentList $completionArgumentText -WorkingDirectory $ProjectRoot | Out-Null

    $zoomSettings = Get-WindowsTerminalSessionZoomSettings -VisualSettings $VisualSettings
    if ($zoomSettings.Enabled -and $zoomSettings.ZoomOutSteps -gt 0) {
        $zoomResult = Invoke-WindowsTerminalSessionZoomOut -WindowsTerminalPath $wtCommand.Source -Steps $zoomSettings.ZoomOutSteps -DelayMilliseconds $zoomSettings.DelayMilliseconds -LogFile $LogFile -ProjectRoot $ProjectRoot
        if ($zoomResult.Applied) {
            Write-Log -Message "Applied Windows Terminal session zoom-out: Ctrl+Minus sent $($zoomResult.Steps) time(s) to panes '$($zoomResult.TargetTitle)'." -Level 'SUCCESS' -Terminal 'LAUNCHER' -LogFile $LogFile -ProjectRoot $ProjectRoot | Out-Null
        } else {
            Write-WarningLog -Message "Windows Terminal session zoom-out was not applied: $($zoomResult.Message)" -Terminal 'LAUNCHER' -LogFile $LogFile -ProjectRoot $ProjectRoot | Out-Null
        }
    }

    return [PSCustomObject]@{
        Engine = 'wt.exe'
        PaneCount = $TerminalCommands.Count
        ArgumentText = "$bootstrapArgumentText ; $completionArgumentText"
    }
}

function Start-TerminalFallbackWindows {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$TerminalCommands,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [string]$LogFile
    )

    Write-WarningLog -Message 'Using fallback: four separate PowerShell windows. No forced 2x2 positioning in Block 05.' -Terminal 'LAUNCHER' -LogFile $LogFile -ProjectRoot $ProjectRoot | Out-Null

    foreach ($terminalCommand in $TerminalCommands) {
        Write-Log -Message "Opening fallback window for $($terminalCommand.Title): powershell.exe $($terminalCommand.ArgumentText)" -Level 'INFO' -Terminal 'LAUNCHER' -LogFile $LogFile -ProjectRoot $ProjectRoot | Out-Null
        Start-Process -FilePath $terminalCommand.Executable -ArgumentList $terminalCommand.ArgumentText -WorkingDirectory $ProjectRoot | Out-Null
    }

    return [PSCustomObject]@{
        Engine = 'PowerShellWindow'
        PaneCount = $TerminalCommands.Count
    }
}

function Get-PrimaryMonitorLayout {
    [CmdletBinding()]
    param()

    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        $workingArea = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
        return [PSCustomObject]@{
            Available = $true
            X = $workingArea.X
            Y = $workingArea.Y
            Width = $workingArea.Width
            Height = $workingArea.Height
        }
    } catch {
        return [PSCustomObject]@{
            Available = $false
            X = $null
            Y = $null
            Width = $null
            Height = $null
            Error = $_.Exception.Message
        }
    }
}
