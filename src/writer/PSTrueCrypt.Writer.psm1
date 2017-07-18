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

Export-ModuleMember -Function Out-Error