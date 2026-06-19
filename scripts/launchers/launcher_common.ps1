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

        [Parameter(Mandatory = $true)]
        [object]$TerminalCommand,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    [void]$ArgumentList.Add($Action)
    if (-not [string]::IsNullOrWhiteSpace($SplitDirection)) {
        [void]$ArgumentList.Add($SplitDirection)
    }

    [void]$ArgumentList.Add('--title')
    [void]$ArgumentList.Add($TerminalCommand.Title)
    [void]$ArgumentList.Add('--startingDirectory')
    [void]$ArgumentList.Add($ProjectRoot)
    [void]$ArgumentList.Add($TerminalCommand.Executable)

    foreach ($argument in $TerminalCommand.ArgumentList) {
        [void]$ArgumentList.Add($argument)
    }
}

function Build-WindowsTerminalArgumentList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$TerminalCommands,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    if ($TerminalCommands.Count -ne 4) {
        throw "Windows Terminal grid requires exactly 4 terminal commands; received $($TerminalCommands.Count)."
    }

    $arguments = New-Object 'System.Collections.Generic.List[string]'

    Add-WindowsTerminalPaneArguments -ArgumentList $arguments -Action 'new-tab' -TerminalCommand $TerminalCommands[0] -ProjectRoot $ProjectRoot
    [void]$arguments.Add(';')
    Add-WindowsTerminalPaneArguments -ArgumentList $arguments -Action 'split-pane' -SplitDirection '-H' -TerminalCommand $TerminalCommands[1] -ProjectRoot $ProjectRoot
    [void]$arguments.Add(';')
    Add-WindowsTerminalPaneArguments -ArgumentList $arguments -Action 'split-pane' -SplitDirection '-V' -TerminalCommand $TerminalCommands[2] -ProjectRoot $ProjectRoot
    [void]$arguments.Add(';')
    [void]$arguments.Add('move-focus')
    [void]$arguments.Add('left')
    [void]$arguments.Add(';')
    Add-WindowsTerminalPaneArguments -ArgumentList $arguments -Action 'split-pane' -SplitDirection '-V' -TerminalCommand $TerminalCommands[3] -ProjectRoot $ProjectRoot

    return @($arguments.ToArray())
}

function Start-TerminalGrid {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$TerminalCommands,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [string]$LogFile
    )

    $wtCommand = Get-WindowsTerminalCommand
    if (-not $wtCommand) {
        throw 'wt.exe was not found.'
    }

    $wtArguments = Build-WindowsTerminalArgumentList -TerminalCommands $TerminalCommands -ProjectRoot $ProjectRoot
    $wtArgumentText = ConvertTo-LauncherArgumentText -Arguments $wtArguments

    Write-Log -Message 'Starting Windows Terminal grid using wt.exe.' -Level 'INFO' -Terminal 'LAUNCHER' -LogFile $LogFile -ProjectRoot $ProjectRoot | Out-Null
    Write-Log -Message "Windows Terminal arguments: $wtArgumentText" -Level 'DEBUG' -Terminal 'LAUNCHER' -LogFile $LogFile -ProjectRoot $ProjectRoot | Out-Null

    Start-Process -FilePath $wtCommand.Source -ArgumentList $wtArgumentText -WorkingDirectory $ProjectRoot | Out-Null

    return [PSCustomObject]@{
        Engine = 'wt.exe'
        PaneCount = $TerminalCommands.Count
        ArgumentText = $wtArgumentText
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
