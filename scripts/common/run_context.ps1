function New-RunId {
    [CmdletBinding()]
    param(
        [string]$Prefix
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $randomChars = -join ((48..57) + (97..122) | Get-Random -Count 6 | ForEach-Object { [char]$_ })

    $safePrefix = $null
    if (-not [string]::IsNullOrWhiteSpace($Prefix)) {
        $safePrefix = ($Prefix -replace '[^a-zA-Z0-9_-]', '_')
    }

    if ($safePrefix) {
        return '{0}_{1}_{2}' -f $safePrefix, $timestamp, $randomChars
    }

    return '{0}_{1}' -f $timestamp, $randomChars
}

function Initialize-RunDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$RunLogDirectory
    )

    $resolvedRunDirectory = Resolve-WmtgProjectPath -Path $RunLogDirectory -ProjectRoot $ProjectRoot

    foreach ($folder in @('terminals', 'summaries')) {
        $folderPath = Join-Path $resolvedRunDirectory $folder
        if (-not (Test-Path -LiteralPath $folderPath)) {
            New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
        }
    }

    return [PSCustomObject]@{
        RunLogDirectory = $resolvedRunDirectory
        TerminalsDirectory = Join-Path $resolvedRunDirectory 'terminals'
        SummariesDirectory = Join-Path $resolvedRunDirectory 'summaries'
    }
}

function Write-RunMetadata {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$RunContext,

        [string]$FileName = 'run_metadata.json'
    )

    $resolvedRunDirectory = Resolve-WmtgProjectPath -Path $RunContext.LogDirectory -ProjectRoot $RunContext.ProjectRoot
    $payload = [ordered]@{
        runId = $RunContext.RunId
        mode = $RunContext.Mode
        source = $RunContext.Source
        startedAt = $RunContext.StartedAt
        dryRun = [bool]$RunContext.DryRun
        projectRoot = $RunContext.ProjectRoot
        logDirectory = $resolvedRunDirectory
        machineName = $env:COMPUTERNAME
        userName = $env:USERNAME
        processId = $PID
    }

    $metadataPath = Join-Path $resolvedRunDirectory $FileName
    $payload | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $metadataPath -Encoding UTF8
    return $metadataPath
}

function Read-RunMetadata {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RunLogDirectory,

        [string]$ProjectRoot,
        [string]$FileName = 'run_metadata.json'
    )

    $resolvedRunDirectory = $RunLogDirectory
    if (Get-Command -Name Resolve-WmtgProjectPath -ErrorAction SilentlyContinue) {
        try {
            $resolvedRunDirectory = Resolve-WmtgProjectPath -Path $RunLogDirectory -ProjectRoot $ProjectRoot
        } catch {
            $resolvedRunDirectory = $RunLogDirectory
        }
    }

    $metadataPath = Join-Path $resolvedRunDirectory $FileName
    if (-not (Test-Path -LiteralPath $metadataPath)) {
        return $null
    }

    try {
        return Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
    } catch {
        return $null
    }
}

function New-RunContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [ValidateSet('visual_only', 'startup_safe', 'maintenance_real', 'maintenance_real_deep')]
        [string]$Mode = 'startup_safe',

        [string]$Source = 'launcher',
        [bool]$DryRun = $true,
        [string]$RunId,
        [string]$BaseDirectory = 'logs'
    )

    if ([string]::IsNullOrWhiteSpace($RunId)) {
        $RunId = New-RunId -Prefix $Source
    }

    $runLogDirectory = New-RunLogDirectory -ProjectRoot $ProjectRoot -BaseDirectory $BaseDirectory -RunId $RunId

    $context = [PSCustomObject]@{
        RunId = $RunId
        Mode = $Mode
        Source = $Source
        DryRun = $DryRun
        ProjectRoot = $ProjectRoot
        LogDirectory = $runLogDirectory
        StartedAt = (Get-Date).ToString('o')
    }

    $directories = Initialize-RunDirectory -ProjectRoot $ProjectRoot -RunLogDirectory $runLogDirectory
    $context | Add-Member -NotePropertyName 'TerminalsDirectory' -NotePropertyValue $directories.TerminalsDirectory
    $context | Add-Member -NotePropertyName 'SummariesDirectory' -NotePropertyValue $directories.SummariesDirectory

    Write-RunMetadata -RunContext $context | Out-Null

    return $context
}
