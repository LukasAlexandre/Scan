param(
    [int]$LoadingDurationSeconds = 1,
    [int]$SpinnerDurationSeconds = 1,
    [int]$TypingDelayMilliseconds = 0
)

$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDirectory 'common.ps1')

function Get-DemoConsoleColor {
    param(
        [string]$ColorName,
        [ConsoleColor]$Fallback = [ConsoleColor]::Gray
    )

    if ([string]::IsNullOrWhiteSpace($ColorName)) {
        return $Fallback
    }

    try {
        return [ConsoleColor]$ColorName
    } catch {
        return $Fallback
    }
}

$projectRoot = Get-ProjectRoot
$visualSettings = Get-VisualSettings -ProjectRoot $projectRoot
$runLogDirectory = New-RunLogDirectory -ProjectRoot $projectRoot -RunId ('visual_demo_' + (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'))
$logFile = Join-Path $runLogDirectory 'visual_demo.log'

Write-SectionLog -Title 'VISUAL DEMO ONLY' -Terminal 'DEMO' -LogFile $logFile -ProjectRoot $projectRoot | Out-Null
Write-ColoredLog -Message 'This demo is visual only. No Windows maintenance command is executed.' -Level 'WARN' -Terminal 'DEMO' -LogFile $logFile -ProjectRoot $projectRoot -Color Yellow -Prefix 'VISUAL' | Out-Null

$terminals = @(
    @{ Id = 'analytics'; Title = 'ANALYTICS'; Subtitle = 'DISM planning lane - visual only' },
    @{ Id = 'scanning'; Title = 'SCANNING'; Subtitle = 'SFC planning lane - visual only' },
    @{ Id = 'processing'; Title = 'PROCESSING'; Subtitle = 'CHKDSK planning lane - visual only' },
    @{ Id = 'cleaning'; Title = 'CLEANING'; Subtitle = 'Optimize planning lane - visual only' }
)

foreach ($terminal in $terminals) {
    $colorName = $visualSettings.colors.($terminal.Id).foreground
    $color = Get-DemoConsoleColor -ColorName $colorName

    Show-TerminalIntro -Title $terminal.Title -Description $terminal.Subtitle -Color $color -TypingDelayMilliseconds $TypingDelayMilliseconds -LogFile $logFile -ProjectRoot $projectRoot
    Show-LoadingBar -Activity "$($terminal.Title) visual startup" -DurationSeconds $LoadingDurationSeconds -Color $color -LogFile $logFile -ProjectRoot $projectRoot -Terminal $terminal.Title
    Show-Spinner -Message "$($terminal.Title) visual pulse" -DurationSeconds $SpinnerDurationSeconds -Color $color -LogFile $logFile -ProjectRoot $projectRoot -Terminal $terminal.Title
    Write-ColoredLog -Message "$($terminal.Title) visual demo completed without maintenance execution." -Level 'SUCCESS' -Terminal $terminal.Title -LogFile $logFile -ProjectRoot $projectRoot -Color $color -Prefix 'VISUAL' | Out-Null
}

Write-SectionLog -Title 'VISUAL DEMO COMPLETE' -Terminal 'DEMO' -LogFile $logFile -ProjectRoot $projectRoot | Out-Null
Write-ColoredLog -Message "Visual demo log: $logFile" -Level 'INFO' -Terminal 'DEMO' -LogFile $logFile -ProjectRoot $projectRoot -Color Cyan -Prefix 'VISUAL' | Out-Null
