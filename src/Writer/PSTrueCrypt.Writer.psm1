using namespace 'System.Management.Automation'
using module .\Error.psm1
using module .\Information.psm1
using module .\Verbose.psm1
using module .\Warning.psm1

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

function Out-Verbose
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Key,

        [Parameter(Mandatory = $False, Position = 2)]
        [string[]]$Format
    )

    [Verbose]::GetInstance().out($Key, $Format)
}

function Out-Warning
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
        [ActionPreference]$Action = [ActionPreference]::Continue
    )

    [Warning]::GetInstance().out($Key, $Format, $Action)
}

Export-ModuleMember -Function Out-Error
Export-ModuleMember -Function Out-Information
Export-ModuleMember -Function Out-Verbose
Export-ModuleMember -Function Out-Warning
