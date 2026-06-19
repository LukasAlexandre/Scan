function New-ExecutionSummary {
    [CmdletBinding()]
    param(
        [string]$Mode = 'unknown',
        [string]$RunId,
        [string]$ProjectRoot,
        [string]$Source = 'unknown',
        [bool]$DryRun = $true
    )

    if ([string]::IsNullOrWhiteSpace($RunId)) {
        $RunId = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    }

    return [ordered]@{
        version = '0.1.0'
        startedAt = (Get-Date).ToString('o')
        finishedAt = $null
        mode = $Mode
        source = $Source
        dryRun = $DryRun
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

function Resolve-WmtgRunLogDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RunLogDirectory,

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
        throw "Refusing to use run log directory outside project root: $resolvedRunDirectory"
    }

    if (-not (Test-Path -LiteralPath $resolvedRunDirectory)) {
        New-Item -ItemType Directory -Path $resolvedRunDirectory -Force | Out-Null
    }

    return $resolvedRunDirectory
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

    $resolvedRunDirectory = Resolve-WmtgRunLogDirectory -RunLogDirectory $RunLogDirectory -ProjectRoot $ProjectRoot

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

function Write-TerminalSummaryJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Summary,

        [Parameter(Mandatory = $true)]
        [string]$RunLogDirectory,

        [Parameter(Mandatory = $true)]
        [string]$TerminalId,

        [string]$ProjectRoot
    )

    $resolvedRunDirectory = Resolve-WmtgRunLogDirectory -RunLogDirectory $RunLogDirectory -ProjectRoot $ProjectRoot
    $summariesDirectory = Join-Path $resolvedRunDirectory 'summaries'
    if (-not (Test-Path -LiteralPath $summariesDirectory)) {
        New-Item -ItemType Directory -Path $summariesDirectory -Force | Out-Null
    }

    $Summary['finishedAt'] = (Get-Date).ToString('o')
    $Summary['terminalId'] = $TerminalId
    if (@($Summary['errors']).Count -gt 0) {
        $Summary['status'] = 'completed_with_errors'
    } else {
        $Summary['status'] = 'completed'
    }

    $summaryPath = Join-Path $summariesDirectory ('{0}_summary.json' -f $TerminalId)
    $Summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $summaryPath -Encoding UTF8
    return $summaryPath
}

function Merge-TerminalSummaries {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RunLogDirectory,

        [string]$ProjectRoot
    )

    $resolvedRunDirectory = Resolve-WmtgRunLogDirectory -RunLogDirectory $RunLogDirectory -ProjectRoot $ProjectRoot
    $summariesDirectory = Join-Path $resolvedRunDirectory 'summaries'
    if (-not (Test-Path -LiteralPath $summariesDirectory)) {
        return @()
    }

    $files = @(Get-ChildItem -LiteralPath $summariesDirectory -Filter '*_summary.json' -File -ErrorAction SilentlyContinue)
    $merged = foreach ($file in $files) {
        $terminalId = $file.BaseName -replace '_summary$', ''
        try {
            $parsed = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
        } catch {
            $parsed = $null
        }

        [PSCustomObject]@{
            TerminalId = $terminalId
            Path = $file.FullName
            Summary = $parsed
        }
    }

    return @($merged)
}

function Get-WmtgExecutionEventStats {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RunLogDirectory,

        [string]$ProjectRoot,
        [string]$FileName = 'execution_events.ndjson'
    )

    $resolvedRunDirectory = Resolve-WmtgRunLogDirectory -RunLogDirectory $RunLogDirectory -ProjectRoot $ProjectRoot
    $eventsPath = Join-Path $resolvedRunDirectory $FileName

    $stats = [PSCustomObject]@{
        TotalCount = 0
        ErrorCount = 0
        WarnCount = 0
    }

    if (-not (Test-Path -LiteralPath $eventsPath)) {
        return $stats
    }

    $lines = @(Get-Content -LiteralPath $eventsPath -ErrorAction SilentlyContinue | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $stats.TotalCount = $lines.Count

    foreach ($line in $lines) {
        try {
            $parsedEvent = $line | ConvertFrom-Json
            switch ($parsedEvent.level) {
                'ERROR' { $stats.ErrorCount++ }
                'WARN' { $stats.WarnCount++ }
            }
        } catch {
            continue
        }
    }

    return $stats
}

function Write-ConsolidatedSummaryJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Summary,

        [Parameter(Mandatory = $true)]
        [string]$RunLogDirectory,

        [string]$Source,
        [string]$FileName = 'summary.json',
        [string]$ProjectRoot
    )

    $resolvedRunDirectory = Resolve-WmtgRunLogDirectory -RunLogDirectory $RunLogDirectory -ProjectRoot $ProjectRoot

    $terminalSummaries = @(Merge-TerminalSummaries -RunLogDirectory $resolvedRunDirectory -ProjectRoot $ProjectRoot)
    $terminalsObject = [ordered]@{}
    $terminalErrorCount = 0
    $hasBlocked = $false
    foreach ($item in $terminalSummaries) {
        $terminalsObject[$item.TerminalId] = $item.Summary
        if ($item.Summary -and $item.Summary.errors) {
            $terminalErrorCount += @($item.Summary.errors).Count
        }
        if ($item.Summary -and ([string]$item.Summary.status) -match 'blocked') {
            $hasBlocked = $true
        }
    }

    $eventStats = Get-WmtgExecutionEventStats -RunLogDirectory $resolvedRunDirectory -ProjectRoot $ProjectRoot

    $ownErrorCount = @($Summary['errors']).Count
    $combinedErrorCount = [Math]::Max($eventStats.ErrorCount, ($ownErrorCount + $terminalErrorCount))

    if (-not [string]::IsNullOrWhiteSpace($Source)) {
        $Summary['source'] = $Source
    } elseif (-not $Summary.Contains('source')) {
        $Summary['source'] = 'launcher'
    }

    $Summary['finishedAt'] = (Get-Date).ToString('o')
    $Summary['terminals'] = $terminalsObject
    $Summary['eventsCount'] = $eventStats.TotalCount
    $Summary['errorsCount'] = $combinedErrorCount
    $Summary['warningsCount'] = $eventStats.WarnCount

    if ($hasBlocked) {
        $Summary['status'] = 'blocked'
    } elseif ($combinedErrorCount -gt 0) {
        $Summary['status'] = 'completed_with_errors'
    } else {
        $Summary['status'] = 'completed'
    }

    $summaryPath = Join-Path $resolvedRunDirectory $FileName
    $Summary | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $summaryPath -Encoding UTF8
    return $summaryPath
}
