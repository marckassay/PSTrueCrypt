function Out-Error
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Key,

        [Parameter(Mandatory = $False, Position = 2)]
        [string]$Recommendment,

        [Parameter(Mandatory = $False, Position = 3)]
        [string[]]$Format,

        [Parameter(Mandatory = $False, Position = 4)]
        [ActionPreference]$Action = [ActionPreference]::Continue
    )
    
    [Error]::GetInstance().out($Key, $Recommendment, $Format, $Action)
}

function Out-Information
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Key,

        [Parameter(Mandatory = $False, Position = 2)]
        [string[]]$Format,

        [Parameter(Mandatory = $False, Position = 3)]
        [string]$Recommendments,

        [Parameter(Mandatory = $False, Position = 4)]
        [ActionPreference]$Action = [ActionPreference]::Continue
    )

    [Information]::GetInstance().out($Key, $Format, $Recommendments, $Action)
}

Export-ModuleMember -Function Out-Error
Export-ModuleMember -Function Out-Information