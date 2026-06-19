function Write-WmtgProgressLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
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

function Show-LoadingBar {
    [CmdletBinding()]
    param(
        [Alias('Label')]
        [string]$Activity = 'Preparing visual diagnostics',

        [int]$Percent = -1,
        [int]$StepPercent = 10,
        [int]$DurationSeconds = 1,
        [int]$DelayMilliseconds = -1,
        [int]$Width = 24,
        [ConsoleColor]$Color = [ConsoleColor]::Gray,
        [Alias('LogFile')]
        [string]$LogPath,
        [string]$ProjectRoot,
        [string]$Terminal = 'VISUAL'
    )

    if ($StepPercent -le 0 -or $StepPercent -gt 100) {
        throw "StepPercent must be between 1 and 100."
    }

    $safeWidth = [Math]::Max(10, [Math]::Min($Width, 60))
    $values = @()
    if ($Percent -ge 0) {
        $values = @([Math]::Max(0, [Math]::Min(100, $Percent)))
    } else {
        for ($value = 0; $value -le 100; $value += $StepPercent) {
            $values += [Math]::Min(100, $value)
        }
        if ($values[-1] -ne 100) {
            $values += 100
        }
    }

    if ($DelayMilliseconds -lt 0) {
        $safeDuration = [Math]::Max(0, [Math]::Min($DurationSeconds, 300))
        $delayCount = [Math]::Max(1, $values.Count - 1)
        $DelayMilliseconds = [Math]::Floor(($safeDuration * 1000) / $delayCount)
    }

    $safeDelay = [Math]::Max(0, [Math]::Min($DelayMilliseconds, 15000))
    foreach ($value in $values) {
        $filled = [Math]::Floor(($value / 100) * $safeWidth)
        $empty = $safeWidth - $filled
        $bar = ('#' * $filled) + ('-' * $empty)
        $line = "[VISUAL] {0} [{1}] {2,3}%" -f $Activity, $bar, $value
        Write-WmtgProgressLine -Line $line -Color $Color -LogPath $LogPath -ProjectRoot $ProjectRoot -Terminal $Terminal

        if ($safeDelay -gt 0 -and $value -lt 100) {
            Start-Sleep -Milliseconds $safeDelay
        }
    }
}

function Show-Spinner {
    [CmdletBinding()]
    param(
        [Alias('Label')]
        [string]$Message = 'Visual activity',

        [int]$DurationSeconds = 1,
        [int]$DurationMilliseconds = -1,
        [int]$IntervalMilliseconds = 100,
        [ConsoleColor]$Color = [ConsoleColor]::Gray,
        [Alias('LogFile')]
        [string]$LogPath,
        [string]$ProjectRoot,
        [string]$Terminal = 'VISUAL'
    )

    if ($DurationMilliseconds -ge 0) {
        $durationMs = $DurationMilliseconds
    } else {
        $durationMs = [Math]::Max(0, [Math]::Min($DurationSeconds, 300)) * 1000
    }

    if ($IntervalMilliseconds -le 0) {
        throw "IntervalMilliseconds must be greater than zero."
    }

    $safeInterval = [Math]::Max(40, [Math]::Min($IntervalMilliseconds, 1000))
    $frames = @('|', '/', '-', '\')
    $stopAt = (Get-Date).AddMilliseconds($durationMs)
    $index = 0

    if (-not [string]::IsNullOrWhiteSpace($LogPath) -and (Get-Command -Name Write-Log -ErrorAction SilentlyContinue)) {
        Write-Log -Message "[VISUAL] Spinner started: $Message" -Level 'DEBUG' -Terminal $Terminal -LogPath $LogPath -ProjectRoot $ProjectRoot -NoConsole -Prefix 'VISUAL' | Out-Null
    }

    while ((Get-Date) -lt $stopAt) {
        $frame = $frames[$index % $frames.Count]
        Write-Host ("`r[VISUAL] {0} {1}" -f $Message, $frame) -NoNewline -ForegroundColor $Color
        Start-Sleep -Milliseconds $safeInterval
        $index++
    }

    Write-Host ("`r[VISUAL] {0} done" -f $Message) -ForegroundColor $Color
    if (-not [string]::IsNullOrWhiteSpace($LogPath) -and (Get-Command -Name Write-Log -ErrorAction SilentlyContinue)) {
        Write-Log -Message "[VISUAL] Spinner finished: $Message" -Level 'DEBUG' -Terminal $Terminal -LogPath $LogPath -ProjectRoot $ProjectRoot -NoConsole -Prefix 'VISUAL' | Out-Null
    }
}

function Start-VisualDelay {
    [CmdletBinding()]
    param(
        [int]$Seconds = 1,
        [int]$Milliseconds = -1,
        [Alias('Label')]
        [string]$Message = 'Visual delay',
        [ConsoleColor]$Color = [ConsoleColor]::Gray,
        [Alias('LogFile')]
        [string]$LogPath,
        [string]$ProjectRoot,
        [string]$Terminal = 'VISUAL'
    )

    if ($Milliseconds -ge 0) {
        $durationMs = $Milliseconds
    } else {
        $durationMs = [Math]::Max(0, [Math]::Min($Seconds, 300)) * 1000
    }

    if ($durationMs -eq 0) {
        return
    }

    Show-Spinner -Message $Message -DurationMilliseconds $durationMs -Color $Color -LogPath $LogPath -ProjectRoot $ProjectRoot -Terminal $Terminal
}
