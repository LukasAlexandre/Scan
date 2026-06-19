param(
    [switch]$DryRun,
    [switch]$Apply,
    [string]$ConfirmationToken = ''
)

$ErrorActionPreference = 'Stop'

$rootDirectory = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $PSScriptRoot
} else {
    (Get-Location).Path
}

$removeScript = Join-Path $rootDirectory 'scripts/startup/remove_scheduled_task.ps1'
if (-not (Test-Path -LiteralPath $removeScript)) {
    throw "Remove scheduled task script not found: $removeScript"
}

$arguments = @{}
if ($DryRun.IsPresent) { $arguments['DryRun'] = $true }
if ($Apply.IsPresent) { $arguments['Apply'] = $true }
if (-not [string]::IsNullOrWhiteSpace($ConfirmationToken)) { $arguments['ConfirmationToken'] = $ConfirmationToken }

& $removeScript @arguments
