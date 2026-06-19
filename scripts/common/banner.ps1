function Get-WmtgBannerLines {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    switch ($Title.ToUpperInvariant()) {
        'ANALYTICS' {
            return @(
                '    ___    _   _    ___    _      __   __  _____  ___   ___   ___ ',
                '   / _ \  | \ | |  / _ \  | |     \ \ / / |_   _| |_ _| / __| / __|',
                '  / /_\ \ |  \| | / /_\ \ | |      \ V /    | |    | | | (__  \__ \',
                '  |  _  | | . ` | |  _  | | |       | |     | |    | |  \__ \  __) |',
                '  |_| |_| |_|\__| |_| |_| |_|___    |_|     |_|   |___| |___/ |___/'
            )
        }
        'SCANNING' {
            return @(
                '  ___    ___    ___    _   _   _   _   ___   _   _    ___ ',
                ' / __|  / __|  / _ \  | \ | | | \ | | |_ _| | \ | |  / __|',
                ' \__ \ | (__  / /_\ \ |  \| | |  \| |  | |  |  \| | | (_ |',
                ' |___/  \___| |_| |_| |_|\__| |_|\__| |___| |_|\__|  \___|'
            )
        }
        'PROCESSING' {
            return @(
                '  ___   ___    ___    ___   ___   ___   ___   ___   _   _   ___ ',
                ' | _ \ | _ \  / _ \  / __| | __| / __| / __| |_ _| | \ | | / __|',
                ' |  _/ |   / | (_) | | (__  | _|  \__ \ \__ \  | |  |  \| | | (_ |',
                ' |_|   |_|_\  \___/   \___| |___| |___/ |___/ |___| |_|\__|  \___|'
            )
        }
        'CLEANING' {
            return @(
                '   ___   _      ___    ___    _   _   ___   _   _    ___ ',
                '  / __| | |    | __|  / _ \  | \ | | |_ _| | \ | |  / __|',
                ' | (__  | |__  | _|  / /_\ \ |  \| |  | |  |  \| | | (_ |',
                '  \___| |____| |___| |_| |_| |_|\__| |___| |_|\__|  \___|'
            )
        }
        default {
            return @(
                ('=' * [Math]::Min([Math]::Max($Title.Length + 8, 24), 80)),
                ("   {0}" -f $Title.ToUpperInvariant()),
                ('=' * [Math]::Min([Math]::Max($Title.Length + 8, 24), 80))
            )
        }
    }
}

function Format-WmtgBannerLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Line,

        [int]$Width = 96
    )

    $safeWidth = [Math]::Max(24, [Math]::Min($Width, 160))
    if ($Line.Length -gt $safeWidth) {
        return $Line.Substring(0, $safeWidth)
    }

    $left = [Math]::Floor(($safeWidth - $Line.Length) / 2)
    return (' ' * $left) + $Line
}

function Write-WmtgVisualLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Line,

        [ConsoleColor]$Color = [ConsoleColor]::Gray,
        [Alias('LogFile')]
        [string]$LogPath,
        [string]$ProjectRoot,
        [string]$Terminal = 'VISUAL'
    )

    Write-Host $Line -ForegroundColor $Color
    if (-not [string]::IsNullOrWhiteSpace($LogPath) -and (Get-Command -Name Write-Log -ErrorAction SilentlyContinue)) {
        Write-Log -Message $Line -Level 'INFO' -Terminal $Terminal -LogPath $LogPath -ProjectRoot $ProjectRoot -NoConsole -Prefix 'VISUAL' | Out-Null
    }
}

function Show-Banner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [string]$Title,

        [ConsoleColor]$Color = [ConsoleColor]::Gray,
        [string]$Subtitle,
        [int]$Width = 96,
        [Alias('LogFile')]
        [string]$LogPath,
        [string]$ProjectRoot
    )

    $safeTitle = $Title.ToUpperInvariant()
    $safeWidth = [Math]::Max(24, [Math]::Min($Width, 160))
    $border = ('=' * $safeWidth)
    $lines = Get-WmtgBannerLines -Title $safeTitle

    Write-WmtgVisualLine -Line $border -Color $Color -LogPath $LogPath -ProjectRoot $ProjectRoot -Terminal $safeTitle
    foreach ($line in $lines) {
        Write-WmtgVisualLine -Line (Format-WmtgBannerLine -Line $line -Width $safeWidth) -Color $Color -LogPath $LogPath -ProjectRoot $ProjectRoot -Terminal $safeTitle
    }

    if (-not [string]::IsNullOrWhiteSpace($Subtitle)) {
        Write-WmtgVisualLine -Line (Format-WmtgBannerLine -Line $Subtitle -Width $safeWidth) -Color $Color -LogPath $LogPath -ProjectRoot $ProjectRoot -Terminal $safeTitle
    }

    Write-WmtgVisualLine -Line $border -Color $Color -LogPath $LogPath -ProjectRoot $ProjectRoot -Terminal $safeTitle
}

function Show-TypingText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [int]$DelayMilliseconds = 8,
        [ConsoleColor]$Color = [ConsoleColor]::Gray,
        [switch]$NoNewLine,
        [Alias('LogFile')]
        [string]$LogPath,
        [string]$ProjectRoot,
        [string]$Terminal = 'VISUAL'
    )

    $safeDelay = [Math]::Max(0, [Math]::Min($DelayMilliseconds, 100))
    foreach ($char in $Text.ToCharArray()) {
        Write-Host -NoNewline $char -ForegroundColor $Color
        if ($safeDelay -gt 0) {
            Start-Sleep -Milliseconds $safeDelay
        }
    }

    if (-not $NoNewLine) {
        Write-Host ''
    }

    if (-not [string]::IsNullOrWhiteSpace($LogPath) -and (Get-Command -Name Write-Log -ErrorAction SilentlyContinue)) {
        Write-Log -Message $Text -Level 'INFO' -Terminal $Terminal -LogPath $LogPath -ProjectRoot $ProjectRoot -NoConsole -Prefix 'VISUAL' | Out-Null
    }
}

function Write-TypewriterText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [int]$DelayMilliseconds = 8,
        [ConsoleColor]$Color = [ConsoleColor]::Gray,
        [switch]$NoNewLine,
        [Alias('LogFile')]
        [string]$LogPath,
        [string]$ProjectRoot,
        [string]$Terminal = 'VISUAL'
    )

    Show-TypingText -Text $Text -DelayMilliseconds $DelayMilliseconds -Color $Color -NoNewLine:$NoNewLine -LogPath $LogPath -ProjectRoot $ProjectRoot -Terminal $Terminal
}

function Show-TerminalIntro {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [string]$Title,

        [string]$Description = 'Visual diagnostics module initialized.',
        [ConsoleColor]$Color = [ConsoleColor]::Gray,
        [int]$TypingDelayMilliseconds = 0,
        [int]$Width = 96,
        [Alias('LogFile')]
        [string]$LogPath,
        [string]$ProjectRoot
    )

    $safeTitle = $Title.ToUpperInvariant()
    Show-Banner -Title $safeTitle -Color $Color -Subtitle $Description -Width $Width -LogPath $LogPath -ProjectRoot $ProjectRoot
    Show-TypingText -Text "[VISUAL] $safeTitle visual layer ready. No maintenance command has been executed." -DelayMilliseconds $TypingDelayMilliseconds -Color $Color -LogPath $LogPath -ProjectRoot $ProjectRoot -Terminal $safeTitle
}
