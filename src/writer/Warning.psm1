using namespace 'System.Resources'
using namespace 'System.Management.Automation'

class Resource
{
    static [Resource] $instance

    static [Resource] GetInstance()
    {
        if ([Resource]::instance -eq $null) {
            [Resource]::instance = [Resource]::new()
        }

        return [Resource]::instance
    }

    $ResourceSet

    Message(
        [string]$Key, 
        [string[]]$Format, 
        [System.Management.Automation.ActionPreference]$Action)
    {
        if(!$this.ResourceSet) {
            $this.ResourceSet = New-Object -TypeName 'System.Resources.ResXResourceSet' -ArgumentList $PSScriptRoot"\..\..\resx\Warning.resx"
        }
        
        $Message = $this.ResourceSet.GetString($Key)

        if($Format) {
            $Message = ($Message -f $Format)
        }

        Write-Warning -Message $Message -WarningAction $Action
    }
}

class Warning
{
    static [void] out([string]$ResourceKey) {
        [Resource]::GetInstance().Message($ResourceKey, $null, [ActionPreference]::Continue)
    }

    static [void] out([string]$ResourceKey, [string[]]$Format) {
        [Resource]::GetInstance().Message($ResourceKey, $Format, [ActionPreference]::Continue)
    }

    static [void] out([string]$ResourceKey, [string[]]$Format, [ActionPreference]$Action)
    {
        [Resource]::GetInstance().Message($ResourceKey, $Format, $Action)
    }
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

        [Parameter(Mandatory = $False, Position = 4)]
        [ActionPreference]$Action = [ActionPreference]::Continue
    )

    [Warning]::out($Key, $Format, $Action)
}

Export-ModuleMember -Function Out-Warning