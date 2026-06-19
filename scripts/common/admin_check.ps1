function Test-IsAdmin {
    [CmdletBinding()]
    param()

    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-AdminOrThrow {
    [CmdletBinding()]
    param(
        [string]$Message = 'Administrator privileges are required for this operation.'
    )

    if (-not (Test-IsAdmin)) {
        throw $Message
    }

    return $true
}
