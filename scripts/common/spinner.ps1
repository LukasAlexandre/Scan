function Show-LoadingBar {
    [CmdletBinding()]
    param(
        [string]$Label = 'Preparing visual diagnostics',
        [int]$StepPercent = 10,
        [int]$DelayMilliseconds = 80,
        [ConsoleColor]$Color = [ConsoleColor]::Gray
    )

    if ($StepPercent -le 0 -or $StepPercent -gt 100) {
        throw "StepPercent must be between 1 and 100."
    }

    for ($percent = 0; $percent -le 100; $percent += $StepPercent) {
        if ($percent -gt 100) {
            $percent = 100
        }

        $filled = [Math]::Floor($percent / 10)
        $empty = 10 - $filled
        $bar = ('#' * $filled) + ('-' * $empty)
        Write-Host ("[VISUAL] {0} [{1}] {2}%" -f $Label, $bar, $percent) -ForegroundColor $Color

        if ($DelayMilliseconds -gt 0 -and $percent -lt 100) {
            Start-Sleep -Milliseconds $DelayMilliseconds
        }
    }
}

function Show-Spinner {
    [CmdletBinding()]
    param(
        [string]$Label = 'Working visually',
        [int]$DurationMilliseconds = 1000,
        [int]$IntervalMilliseconds = 100,
        [ConsoleColor]$Color = [ConsoleColor]::Gray
    )

    if ($DurationMilliseconds -lt 0) {
        throw "DurationMilliseconds cannot be negative."
    }
    if ($IntervalMilliseconds -le 0) {
        throw "IntervalMilliseconds must be greater than zero."
    }

    $frames = @('|', '/', '-', '\')
    $stopAt = (Get-Date).AddMilliseconds($DurationMilliseconds)
    $index = 0

    while ((Get-Date) -lt $stopAt) {
        $frame = $frames[$index % $frames.Count]
        Write-Host ("`r[VISUAL] {0} {1}" -f $Label, $frame) -NoNewline -ForegroundColor $Color
        Start-Sleep -Milliseconds $IntervalMilliseconds
        $index++
    }

    Write-Host ("`r[VISUAL] {0} done" -f $Label) -ForegroundColor $Color
}

function Start-VisualDelay {
    [CmdletBinding()]
    param(
        [int]$Milliseconds = 500,
        [string]$Label = 'Visual delay',
        [ConsoleColor]$Color = [ConsoleColor]::Gray
    )

    if ($Milliseconds -lt 0) {
        throw "Milliseconds cannot be negative."
    }

    if ($Milliseconds -eq 0) {
        return
    }

    Show-Spinner -Label $Label -DurationMilliseconds $Milliseconds -Color $Color
}
