param(
    [ValidateSet('visual_only', 'startup_safe', 'maintenance_real', 'maintenance_real_deep')]
    [string]$Mode = 'startup_safe',
    [string]$RunLogDirectory = '',
    [switch]$NoPause,
    [switch]$DryRun
)

$terminalScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $terminalScriptDirectory 'terminal_runner.ps1')

Start-TerminalRoutine -TerminalId 'analytics' -Mode $Mode -RunLogDirectory $RunLogDirectory -NoPause:$NoPause -DryRun
