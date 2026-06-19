param(
    [switch]$DryRun,
    [switch]$Apply,
    [string]$ConfirmationToken = '',
    [switch]$UseFallback,
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'

$rootDirectory = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $PSScriptRoot
} else {
    (Get-Location).Path
}

$createScript = Join-Path $rootDirectory 'scripts/startup/create_scheduled_task.ps1'
if (-not (Test-Path -LiteralPath $createScript)) {
    throw "Create scheduled task script not found: $createScript"
}

$arguments = @{}
if ($DryRun.IsPresent) { $arguments['DryRun'] = $true }
if ($Apply.IsPresent) { $arguments['Apply'] = $true }
if (-not [string]::IsNullOrWhiteSpace($ConfirmationToken)) { $arguments['ConfirmationToken'] = $ConfirmationToken }
if ($UseFallback.IsPresent) { $arguments['UseFallback'] = $true }
if ($NoPause.IsPresent) { $arguments['NoPause'] = $true }

& $createScript @arguments
