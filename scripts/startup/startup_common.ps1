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

function Resolve-StartupProjectPath {
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
        throw "Refusing to use startup path outside project root: $fullPath"
    }

    return $fullPath
}

function Get-StartupTaskUserId {
    [CmdletBinding()]
    param()

    if (-not [string]::IsNullOrWhiteSpace($env:USERDOMAIN) -and -not [string]::IsNullOrWhiteSpace($env:USERNAME)) {
        return '{0}\{1}' -f $env:USERDOMAIN, $env:USERNAME
    }

    return [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
}

function New-StartupScheduledTaskPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [object]$TerminalsConfig,

        [Parameter(Mandatory = $true)]
        [object]$ScheduleSettings,

        [switch]$UseFallback,
        [switch]$NoPause
    )

    $taskName = $ScheduleSettings.scheduledTask.taskName
    if ([string]::IsNullOrWhiteSpace($taskName)) {
        $taskName = 'WindowsMaintenanceTerminalGrid'
    }

    $targetRelativePath = 'scripts/startup/launcher_startup_safe.ps1'
    $targetPath = Resolve-StartupProjectPath -Path $targetRelativePath -ProjectRoot $ProjectRoot
    $delay = Get-StartupSafeDelay -ScheduleSettings $ScheduleSettings -DelaySeconds -1

    $launcherArguments = @('-DryRun')
    if ($UseFallback.IsPresent) {
        $launcherArguments += '-UseFallback'
    }
    if ($NoPause.IsPresent) {
        $launcherArguments += '-NoPause'
    }

    $powershellArguments = @(
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        $targetPath
    ) + $launcherArguments

    return [PSCustomObject]@{
        TaskName = $taskName
        Description = 'Open Windows Maintenance Terminal Grid in startup_safe dry-run mode at user logon.'
        TargetRelativePath = $targetRelativePath
        TargetPath = $targetPath
        PowerShellExe = 'powershell.exe'
        PowerShellArguments = @($powershellArguments)
        ActionArguments = ConvertTo-StartupArgumentText -Arguments $powershellArguments
        Trigger = 'AtLogon'
        DelaySeconds = $delay.Seconds
        DelaySource = $delay.Source
        UserId = Get-StartupTaskUserId
        LogonType = 'Interactive'
        RunLevel = 'Limited'
        DryRun = $true
        StartupMode = $ScheduleSettings.startup.mode
        AllowStartupHeavyCommands = [bool]$TerminalsConfig.allowStartupHeavyCommands
        AllowHeavyCommandsOnStartup = [bool]$ScheduleSettings.startup.allowHeavyCommandsOnStartup
        AllowRealMaintenance = [bool]$TerminalsConfig.allowRealMaintenance
        AutoCreate = [bool]$ScheduleSettings.scheduledTask.autoCreate
    }
}

function Test-StartupScheduledTaskPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Plan,

        [Parameter(Mandatory = $true)]
        [object]$TerminalsConfig,

        [Parameter(Mandatory = $true)]
        [object]$ScheduleSettings
    )

    $violations = @()

    if ($ScheduleSettings.startup.mode -ne 'startup_safe') {
        $violations += "startup.mode must be 'startup_safe'."
    }
    if ([bool]$ScheduleSettings.startup.allowHeavyCommandsOnStartup) {
        $violations += 'startup.allowHeavyCommandsOnStartup must remain false.'
    }
    if ([bool]$TerminalsConfig.allowStartupHeavyCommands) {
        $violations += 'allowStartupHeavyCommands must remain false.'
    }
    if ([bool]$TerminalsConfig.allowRealMaintenance) {
        $violations += 'allowRealMaintenance must remain false.'
    }
    if ($ScheduleSettings.scheduledTask.taskName -ne 'WindowsMaintenanceTerminalGrid') {
        $violations += 'scheduledTask.taskName must be WindowsMaintenanceTerminalGrid.'
    }
    if ($Plan.TargetRelativePath -ne 'scripts/startup/launcher_startup_safe.ps1') {
        $violations += 'scheduled task target must be scripts/startup/launcher_startup_safe.ps1.'
    }
    if ((Split-Path -Leaf $Plan.TargetPath) -ne 'launcher_startup_safe.ps1') {
        $violations += 'scheduled task target file must be launcher_startup_safe.ps1.'
    }
    if ($Plan.ActionArguments -notmatch '-DryRun') {
        $violations += 'scheduled task action must include -DryRun.'
    }
    if ($Plan.TargetPath -match 'maintenance[_-]real' -or $Plan.ActionArguments -match 'maintenance[_-]real') {
        $violations += 'scheduled task action must not target maintenance real.'
    }
    if ($Plan.RunLevel -ne 'Limited') {
        $violations += 'scheduled task run level must remain Limited by default.'
    }
    if ($Plan.LogonType -ne 'Interactive') {
        $violations += 'scheduled task logon type must remain Interactive.'
    }

    return [PSCustomObject]@{
        IsSafe = ($violations.Count -eq 0)
        Violations = $violations
    }
}
