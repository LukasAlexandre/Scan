function Resolve-WmtgProjectPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [string]$ProjectRoot
    )

    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
        if (Get-Command -Name Get-ProjectRoot -ErrorAction SilentlyContinue) {
            $ProjectRoot = Get-ProjectRoot
        } else {
            $ProjectRoot = (Get-Location).Path
        }
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

function Get-WmtgLogColor {
    [CmdletBinding()]
    param(
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS', 'DEBUG')]
        [string]$Level = 'INFO',

        [ConsoleColor]$Fallback = [ConsoleColor]::Gray
    )

    switch ($Level) {
        'INFO' { return [ConsoleColor]::Cyan }
        'WARN' { return [ConsoleColor]::Yellow }
        'ERROR' { return [ConsoleColor]::Red }
        'SUCCESS' { return [ConsoleColor]::Green }
        'DEBUG' { return [ConsoleColor]::DarkGray }
        default { return $Fallback }
    }
}

function New-RunLogDirectory {
    [CmdletBinding()]
    param(
        [string]$ProjectRoot,
        [string]$BaseDirectory = 'logs',
        [string]$RunId
    )

    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
        if (Get-Command -Name Get-ProjectRoot -ErrorAction SilentlyContinue) {
            $ProjectRoot = Get-ProjectRoot
        } else {
            $ProjectRoot = (Get-Location).Path
        }
    }

    if ([string]::IsNullOrWhiteSpace($RunId)) {
        $RunId = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    }

    $basePath = Resolve-WmtgProjectPath -Path $BaseDirectory -ProjectRoot $ProjectRoot
    $runPath = Resolve-WmtgProjectPath -Path (Join-Path $BaseDirectory $RunId) -ProjectRoot $ProjectRoot

    if (-not (Test-Path -LiteralPath $basePath)) {
        New-Item -ItemType Directory -Path $basePath -Force | Out-Null
    }
    if (-not (Test-Path -LiteralPath $runPath)) {
        New-Item -ItemType Directory -Path $runPath -Force | Out-Null
    }

    return $runPath
}

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS', 'DEBUG')]
        [string]$Level = 'INFO',

        [string]$Terminal = 'SYSTEM',

        [Alias('LogFile')]
        [string]$LogPath,

        [string]$ProjectRoot,
        [switch]$NoConsole,
        [ConsoleColor]$Color,
        [string]$Prefix = 'STATUS'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    if (-not $PSBoundParameters.ContainsKey('Color')) {
        $Color = Get-WmtgLogColor -Level $Level
    }

    $safePrefix = if ([string]::IsNullOrWhiteSpace($Prefix)) { 'STATUS' } else { $Prefix.ToUpperInvariant() }
    $safeTerminal = if ([string]::IsNullOrWhiteSpace($Terminal)) { 'SYSTEM' } else { $Terminal.ToUpperInvariant() }
    $line = "[{0}] [{1}] [{2}] [{3}] {4}" -f $timestamp, $safeTerminal, $Level, $safePrefix, $Message

    if (-not $NoConsole) {
        Write-Host $line -ForegroundColor $Color
    }

    if (-not [string]::IsNullOrWhiteSpace($LogPath)) {
        $resolvedLogPath = Resolve-WmtgProjectPath -Path $LogPath -ProjectRoot $ProjectRoot
        $parent = Split-Path -Parent $resolvedLogPath
        if (-not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        Add-Content -LiteralPath $resolvedLogPath -Value $line -Encoding UTF8
    }

    return $line
}

function Write-ColoredLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS', 'DEBUG')]
        [string]$Level = 'INFO',

        [string]$Terminal = 'SYSTEM',

        [Alias('LogFile')]
        [string]$LogPath,

        [string]$ProjectRoot,
        [ConsoleColor]$Color,
        [string]$Prefix = 'VISUAL'
    )

    if ($PSBoundParameters.ContainsKey('Color')) {
        return Write-Log -Message $Message -Level $Level -Terminal $Terminal -LogPath $LogPath -ProjectRoot $ProjectRoot -Color $Color -Prefix $Prefix
    }

    return Write-Log -Message $Message -Level $Level -Terminal $Terminal -LogPath $LogPath -ProjectRoot $ProjectRoot -Prefix $Prefix
}

function Write-SectionLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [string]$Terminal = 'SYSTEM',

        [Alias('LogFile')]
        [string]$LogPath,

        [string]$ProjectRoot,
        [int]$Width = 72
    )

    $safeWidth = [Math]::Max(24, [Math]::Min($Width, 140))
    $label = " $Title "
    $side = [Math]::Max(4, [Math]::Floor(($safeWidth - $label.Length) / 2))
    $line = ('=' * $side) + $label + ('=' * $side)
    if ($line.Length -gt $safeWidth) {
        $line = $line.Substring(0, $safeWidth)
    }

    return Write-Log -Message $line -Level 'INFO' -Terminal $Terminal -LogPath $LogPath -ProjectRoot $ProjectRoot -Color Cyan -Prefix 'SECTION'
}

function Write-WarningLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [string]$Terminal = 'SYSTEM',

        [Alias('LogFile')]
        [string]$LogPath,

        [string]$ProjectRoot
    )

    return Write-Log -Message $Message -Level 'WARN' -Terminal $Terminal -LogPath $LogPath -ProjectRoot $ProjectRoot -Color Yellow -Prefix 'WARN'
}

function Write-ErrorLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [string]$Terminal = 'SYSTEM',

        [Alias('LogFile')]
        [string]$LogPath,

        [string]$ProjectRoot
    )

    return Write-Log -Message $Message -Level 'ERROR' -Terminal $Terminal -LogPath $LogPath -ProjectRoot $ProjectRoot -Color Red -Prefix 'ERROR'
}
