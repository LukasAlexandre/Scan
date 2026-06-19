$script:WmtgStartupDirectory = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $PSScriptRoot
} elseif (-not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    (Get-Location).Path
}

function Resolve-StartupProjectRoot {
    [CmdletBinding()]
    param(
        [string]$StartPath
    )

    if ([string]::IsNullOrWhiteSpace($StartPath)) {
        $StartPath = $script:WmtgStartupDirectory
    }

    if (-not (Test-Path -LiteralPath $StartPath)) {
        throw "Startup start path not found: $StartPath"
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

    throw "Project root not found from startup path: $StartPath"
}

function Get-StartupSafeDelay {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$ScheduleSettings,

        [int]$DelaySeconds = -1,
        [int]$FallbackDelaySeconds = 20,
        [int]$MaxDelaySeconds = 300
    )

    $delaySource = 'config'
    $rawDelay = $null

    if ($DelaySeconds -ge 0) {
        $delaySource = 'parameter'
        $rawDelay = $DelaySeconds
    } elseif ($ScheduleSettings -and $ScheduleSettings.startup) {
        $rawDelay = $ScheduleSettings.startup.delaySeconds
    }

    $delay = 0
    if ($null -eq $rawDelay -or -not [int]::TryParse([string]$rawDelay, [ref]$delay) -or $delay -lt 0) {
        $delaySource = 'fallback'
        $delay = $FallbackDelaySeconds
    }

    if ($delay -gt $MaxDelaySeconds) {
        $delaySource = '{0}_capped' -f $delaySource
        $delay = $MaxDelaySeconds
    }

    return [PSCustomObject]@{
        Seconds = $delay
        Source = $delaySource
        Maximum = $MaxDelaySeconds
        Fallback = $FallbackDelaySeconds
    }
}

function Test-StartupSafeConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$TerminalsConfig,

        [Parameter(Mandatory = $true)]
        [object]$ScheduleSettings
    )

    $violations = @()

    if ($ScheduleSettings.startup.mode -ne 'startup_safe') {
        $violations += "startup.mode must be 'startup_safe'."
    }
    if ([bool]$TerminalsConfig.allowStartupHeavyCommands) {
        $violations += 'allowStartupHeavyCommands must remain false.'
    }
    if ([bool]$ScheduleSettings.startup.allowHeavyCommandsOnStartup) {
        $violations += 'startup.allowHeavyCommandsOnStartup must remain false.'
    }
    if ([bool]$TerminalsConfig.allowRealMaintenance) {
        $violations += 'allowRealMaintenance must remain false.'
    }
    if ([bool]$ScheduleSettings.scheduledTask.autoCreate) {
        $violations += 'scheduledTask.autoCreate must remain false.'
    }
    if ([bool]$ScheduleSettings.startup.enabled) {
        $violations += 'startup.enabled must remain false until the scheduling block.'
    }

    return [PSCustomObject]@{
        IsSafe = ($violations.Count -eq 0)
        Violations = $violations
    }
}

function Resolve-StartupRunLogDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [object]$ScheduleSettings
    )

    $baseDirectory = 'logs'
    if ($ScheduleSettings.logs -and -not [string]::IsNullOrWhiteSpace($ScheduleSettings.logs.baseDirectory)) {
        $baseDirectory = $ScheduleSettings.logs.baseDirectory
    }

    $runId = 'startup_safe_{0}' -f (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')
    return New-RunLogDirectory -ProjectRoot $ProjectRoot -BaseDirectory $baseDirectory -RunId $runId
}

function Build-StartupSafeLauncherArguments {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RunLogDirectory,

        [switch]$UseFallback,
        [switch]$NoPause
    )

    $arguments = @(
        '-Mode',
        'startup_safe',
        '-RunLogDirectory',
        $RunLogDirectory,
        '-DryRun'
    )

    if ($UseFallback.IsPresent) {
        $arguments += '-UseFallback'
    }
    if ($NoPause.IsPresent) {
        $arguments += '-NoPause'
    }

    return @($arguments)
}

function ConvertTo-StartupArgumentText {
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
