function Join-WmtgCommandLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [string[]]$Arguments = @()
    )

    $parts = @($Command) + @($Arguments)
    return ($parts | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join ' '
}

function ConvertTo-WmtgProcessArgument {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    if ($Value -match '[\s"]') {
        return '"' + ($Value -replace '"', '\"') + '"'
    }

    return $Value
}

function Test-WmtgKnownMaintenanceCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [string[]]$Arguments = @()
    )

    $commandLine = (Join-WmtgCommandLine -Command $Command -Arguments $Arguments).ToLowerInvariant()
    $normalized = ($commandLine -replace '\s+', ' ').Trim()

    $blockedPatterns = @(
        'dism /online /cleanup-image /restorehealth',
        'dism.exe /online /cleanup-image /restorehealth',
        'sfc /scannow',
        'sfc.exe /scannow',
        'chkdsk c: /r',
        'chkdsk.exe c: /r',
        'chkdsk c: /scan',
        'chkdsk.exe c: /scan',
        'defrag c: /o /u /v',
        'defrag.exe c: /o /u /v'
    )

    foreach ($pattern in $blockedPatterns) {
        if ($normalized -eq $pattern -or $normalized.Contains($pattern)) {
            return $true
        }
    }

    return $false
}

function Test-WmtgAllowedExecutable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [string[]]$AllowedExecutables = @('DISM', 'DISM.exe', 'sfc', 'sfc.exe', 'chkdsk', 'chkdsk.exe', 'defrag', 'defrag.exe')
    )

    $commandName = [System.IO.Path]::GetFileName($Command)
    if ([string]::IsNullOrWhiteSpace($commandName)) {
        return $false
    }

    foreach ($allowed in $AllowedExecutables) {
        if ($commandName.Equals($allowed, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }

    return $false
}

function Write-WmtgRunnerLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS', 'DEBUG')]
        [string]$Level = 'INFO',

        [string]$Terminal = 'COMMAND',
        [string]$LogPath,
        [string]$ProjectRoot
    )

    if (Get-Command -Name Write-Log -ErrorAction SilentlyContinue) {
        Write-Log -Message $Message -Level $Level -Terminal $Terminal -LogPath $LogPath -ProjectRoot $ProjectRoot | Out-Null
    } else {
        Write-Host ("[{0}] [{1}] {2}" -f $Terminal, $Level, $Message)
    }
}

function Invoke-DryRunCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [string[]]$Arguments = @(),
        [string]$Terminal = 'COMMAND',
        [string]$Mode = 'dry_run',
        [string]$LogPath,
        [string]$ProjectRoot
    )

    $commandLine = Join-WmtgCommandLine -Command $Command -Arguments $Arguments
    Write-WmtgRunnerLog -Message "DRY RUN: would execute '$commandLine' in mode '$Mode'." -Level 'INFO' -Terminal $Terminal -LogPath $LogPath -ProjectRoot $ProjectRoot

    return [PSCustomObject]@{
        command = $Command
        arguments = $Arguments
        commandLine = $commandLine
        mode = $Mode
        terminal = $Terminal
        dryRun = $true
        status = 'dry_run'
        exitCode = $null
        stdout = @()
        stderr = @()
        error = $null
        startedAt = (Get-Date).ToString('o')
        finishedAt = (Get-Date).ToString('o')
    }
}

function Invoke-CommandWithLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [string[]]$Arguments = @(),
        [string]$Terminal = 'COMMAND',
        [string]$Mode = 'unknown',
        [string]$LogPath,
        [string]$ProjectRoot,
        [bool]$DryRun = $true,
        [bool]$AllowRealMaintenance = $false,
        [bool]$AllowSessionRealMaintenance = $false,
        [bool]$RequireAdmin = $false,
        [bool]$RequireExplicitConfirmation = $true,
        [string]$ConfirmationToken,
        [string]$RequiredConfirmationToken = 'CONFIRM_REAL_EXECUTION',
        [string[]]$AllowedExecutables = @('DISM', 'DISM.exe', 'sfc', 'sfc.exe', 'chkdsk', 'chkdsk.exe', 'defrag', 'defrag.exe'),
        [switch]$AllowKnownMaintenanceCommand
    )

    if ($DryRun) {
        return Invoke-DryRunCommand -Command $Command -Arguments $Arguments -Terminal $Terminal -Mode $Mode -LogPath $LogPath -ProjectRoot $ProjectRoot
    }

    if (-not ($AllowRealMaintenance -or $AllowSessionRealMaintenance)) {
        throw "Real command execution blocked because AllowRealMaintenance and AllowSessionRealMaintenance are false."
    }

    if ($RequireExplicitConfirmation -and $ConfirmationToken -ne $RequiredConfirmationToken) {
        throw "Real command execution blocked because explicit confirmation token was not provided."
    }

    if (-not (Test-WmtgAllowedExecutable -Command $Command -AllowedExecutables $AllowedExecutables)) {
        throw "Real command execution blocked because '$Command' is outside the allowed executable list."
    }

    if ($RequireAdmin) {
        if (-not (Get-Command -Name Test-IsAdmin -ErrorAction SilentlyContinue)) {
            throw "Real command execution requested admin validation, but Test-IsAdmin is not loaded."
        }
        if (-not (Test-IsAdmin)) {
            throw "Real command execution blocked because administrator privileges were not detected."
        }
    }

    $isKnownMaintenance = Test-WmtgKnownMaintenanceCommand -Command $Command -Arguments $Arguments
    if ($isKnownMaintenance -and -not $AllowKnownMaintenanceCommand) {
        throw "Known Windows maintenance command blocked without AllowKnownMaintenanceCommand."
    }

    $startedAt = Get-Date
    $commandLine = Join-WmtgCommandLine -Command $Command -Arguments $Arguments
    Write-WmtgRunnerLog -Message "Executing command: $commandLine" -Level 'INFO' -Terminal $Terminal -LogPath $LogPath -ProjectRoot $ProjectRoot

    $stdout = @()
    $stderr = @()
    $exitCode = $null
    $errorMessage = $null
    $status = 'completed'

    try {
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = New-Object System.Diagnostics.ProcessStartInfo
        $process.StartInfo.FileName = $Command
        $process.StartInfo.Arguments = (($Arguments | ForEach-Object { ConvertTo-WmtgProcessArgument -Value $_ }) -join ' ')
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.RedirectStandardOutput = $true
        $process.StartInfo.RedirectStandardError = $true
        $process.StartInfo.CreateNoWindow = $true

        $null = $process.Start()
        $stdoutText = $process.StandardOutput.ReadToEnd()
        $stderrText = $process.StandardError.ReadToEnd()
        $process.WaitForExit()
        $exitCode = $process.ExitCode

        if (-not [string]::IsNullOrWhiteSpace($stdoutText)) {
            $stdout = $stdoutText -split "`r?`n" | Where-Object { $_ -ne '' }
            foreach ($line in $stdout) {
                Write-WmtgRunnerLog -Message "STDOUT: $line" -Level 'DEBUG' -Terminal $Terminal -LogPath $LogPath -ProjectRoot $ProjectRoot
            }
        }

        if (-not [string]::IsNullOrWhiteSpace($stderrText)) {
            $stderr = $stderrText -split "`r?`n" | Where-Object { $_ -ne '' }
            foreach ($line in $stderr) {
                Write-WmtgRunnerLog -Message "STDERR: $line" -Level 'WARN' -Terminal $Terminal -LogPath $LogPath -ProjectRoot $ProjectRoot
            }
        }

        if ($exitCode -ne 0) {
            $status = 'failed'
        }
    } catch {
        $status = 'error'
        $errorMessage = $_.Exception.Message
        Write-WmtgRunnerLog -Message "Command error: $errorMessage" -Level 'ERROR' -Terminal $Terminal -LogPath $LogPath -ProjectRoot $ProjectRoot
    }

    $finishedAt = Get-Date
    Write-WmtgRunnerLog -Message "Command finished with status '$status' and exit code '$exitCode'." -Level 'INFO' -Terminal $Terminal -LogPath $LogPath -ProjectRoot $ProjectRoot

    return [PSCustomObject]@{
        command = $Command
        arguments = $Arguments
        commandLine = $commandLine
        mode = $Mode
        terminal = $Terminal
        dryRun = $false
        status = $status
        exitCode = $exitCode
        stdout = $stdout
        stderr = $stderr
        error = $errorMessage
        startedAt = $startedAt.ToString('o')
        finishedAt = $finishedAt.ToString('o')
    }
}
