function New-ExecutionSummary {
    [CmdletBinding()]
    param(
        [string]$Mode = 'unknown',
        [string]$RunId,
        [string]$ProjectRoot
    )

    if ([string]::IsNullOrWhiteSpace($RunId)) {
        $RunId = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    }

    return [ordered]@{
        version = '0.1.0'
        startedAt = (Get-Date).ToString('o')
        finishedAt = $null
        mode = $Mode
        runId = $RunId
        projectRoot = $ProjectRoot
        entries = @()
        status = 'created'
        errors = @()
    }
}

function Add-SummaryEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Summary,

        [string]$Terminal = 'SYSTEM',
        [string]$Command,
        [string[]]$Arguments = @(),
        [bool]$DryRun = $true,
        [string]$Status = 'unknown',
        [Nullable[int]]$ExitCode,
        [string]$ErrorMessage,
        [string]$StartedAt,
        [string]$FinishedAt
    )

    if ([string]::IsNullOrWhiteSpace($StartedAt)) {
        $StartedAt = (Get-Date).ToString('o')
    }
    if ([string]::IsNullOrWhiteSpace($FinishedAt)) {
        $FinishedAt = (Get-Date).ToString('o')
    }

    $entry = [ordered]@{
        terminal = $Terminal
        command = $Command
        arguments = $Arguments
        plannedCommand = (($Command, ($Arguments -join ' ')) -join ' ').Trim()
        dryRun = $DryRun
        status = $Status
        exitCode = $ExitCode
        error = $ErrorMessage
        startedAt = $StartedAt
        finishedAt = $FinishedAt
    }

    $entries = @($Summary['entries'])
    $Summary['entries'] = $entries + @($entry)

    if (-not [string]::IsNullOrWhiteSpace($ErrorMessage)) {
        $errors = @($Summary['errors'])
        $Summary['errors'] = $errors + @($ErrorMessage)
    }

    return $Summary
}

function Write-SummaryJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Summary,

        [Parameter(Mandatory = $true)]
        [string]$RunLogDirectory,

        [string]$FileName = 'summary.json',
        [string]$ProjectRoot
    )

    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
        if (Get-Command -Name Get-ProjectRoot -ErrorAction SilentlyContinue) {
            $ProjectRoot = Get-ProjectRoot
        } else {
            $ProjectRoot = (Get-Location).Path
        }
    }

    if ([System.IO.Path]::IsPathRooted($RunLogDirectory)) {
        $resolvedRunDirectory = [System.IO.Path]::GetFullPath($RunLogDirectory)
    } elseif (Get-Command -Name Resolve-WmtgProjectPath -ErrorAction SilentlyContinue) {
        $resolvedRunDirectory = Resolve-WmtgProjectPath -Path $RunLogDirectory -ProjectRoot $ProjectRoot
    } else {
        $resolvedRunDirectory = Join-Path $ProjectRoot $RunLogDirectory
    }

    $resolvedRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
    if (-not $resolvedRunDirectory.StartsWith($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to write summary outside project root: $resolvedRunDirectory"
    }

    if (-not (Test-Path -LiteralPath $resolvedRunDirectory)) {
        New-Item -ItemType Directory -Path $resolvedRunDirectory -Force | Out-Null
    }

    $Summary['finishedAt'] = (Get-Date).ToString('o')
    if (@($Summary['errors']).Count -gt 0) {
        $Summary['status'] = 'completed_with_errors'
    } else {
        $Summary['status'] = 'completed'
    }

    $summaryPath = Join-Path $resolvedRunDirectory $FileName
    $Summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $summaryPath -Encoding UTF8
    return $summaryPath
}
