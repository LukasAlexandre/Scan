function Get-WmtgBannerLines {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    switch ($Name.ToUpperInvariant()) {
        'ANALYTICS' {
            return @(
                '    A    N   N   A    L      Y   Y  TTTTT  III   CCCC   SSSS ',
                '   A A   NN  N  A A   L       Y Y     T     I   C      S     ',
                '  AAAAA  N N N AAAAA  L        Y      T     I   C       SSS  ',
                ' A     A N  NN A     A L        Y      T     I   C          S ',
                ' A     A N   N A     A LLLLL    Y      T    III   CCCC  SSSS  '
            )
        }
        'SCANNING' {
            return @(
                ' SSSS   CCCC    A    N   N  N   N  III  N   N   GGGG ',
                ' S     C       A A   NN  N  NN  N   I   NN  N  G     ',
                '  SSS  C      AAAAA  N N N  N N N   I   N N N  G  GG ',
                '     S C      A   A  N  NN  N  NN   I   N  NN  G   G ',
                ' SSSS   CCCC  A   A  N   N  N   N  III  N   N   GGG  '
            )
        }
        'PROCESSING' {
            return @(
                ' PPPP   RRRR    OOO   CCCC  EEEEE  SSSS   SSSS  III  N   N   GGGG ',
                ' P   P  R   R  O   O C      E      S      S       I   NN  N  G     ',
                ' PPPP   RRRR   O   O C      EEEE    SSS    SSS    I   N N N  G  GG ',
                ' P      R  R   O   O C      E          S      S   I   N  NN  G   G ',
                ' P      R   R   OOO   CCCC  EEEEE  SSSS   SSSS  III  N   N   GGG  '
            )
        }
        'CLEANING' {
            return @(
                '  CCCC  L      EEEEE    A    N   N  III  N   N   GGGG ',
                ' C      L      E       A A   NN  N   I   NN  N  G     ',
                ' C      L      EEEE   AAAAA  N N N   I   N N N  G  GG ',
                ' C      L      E      A   A  N  NN   I   N  NN  G   G ',
                '  CCCC  LLLLL  EEEEE  A   A  N   N  III  N   N   GGG  '
            )
        }
        default {
            return @($Name.ToUpperInvariant())
        }
    }
}

function Show-Banner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [ConsoleColor]$Color = [ConsoleColor]::Gray
    )

    $lines = Get-WmtgBannerLines -Name $Name
    foreach ($line in $lines) {
        Write-Host $line -ForegroundColor $Color
    }
}

function Show-TypingText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [int]$DelayMilliseconds = 8,
        [ConsoleColor]$Color = [ConsoleColor]::Gray,
        [switch]$NoNewLine
    )

    foreach ($char in $Text.ToCharArray()) {
        Write-Host -NoNewline $char -ForegroundColor $Color
        if ($DelayMilliseconds -gt 0) {
            Start-Sleep -Milliseconds $DelayMilliseconds
        }
    }

    if (-not $NoNewLine) {
        Write-Host ''
    }
}

function Show-TerminalIntro {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$Description = 'Visual diagnostics module initialized.',
        [ConsoleColor]$Color = [ConsoleColor]::Gray,
        [int]$TypingDelayMilliseconds = 0
    )

    Show-Banner -Name $Name -Color $Color
    Show-TypingText -Text "[VISUAL] $Description" -DelayMilliseconds $TypingDelayMilliseconds -Color $Color
}
