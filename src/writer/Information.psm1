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
        [string]$Recommendments, 
        [System.Management.Automation.ActionPreference]$Action)
    {
        if(!$this.ResourceSet) {
            $this.ResourceSet = New-Object -TypeName 'System.Resources.ResXResourceSet' -ArgumentList "$PSScriptRoot\..\..\resx\Information.resx"
        }
        
        $Message = $this.ResourceSet.GetString($Key)

        # TODO: this is just hanging.  was I to ammend this to Message?
        $Recommendment = ''
        if($Recommendments) {
            $Recommendment = $this.ResourceSet.GetString($Recommendments)
        }

        if($Format) {
            $Message = ($Message -f $Format)
        }

        if(!$Action) {
            $Action = [ActionPreference]::Continue
        }

        Write-Information -MessageData $Message -InformationAction $Action
    }
}

class Information
{
    static [void] out([string]$ResourceKey) {
        [Resource]::GetInstance().Message($ResourceKey, $null, $null, [ActionPreference]::Continue)
    }

    static [void] out([string]$ResourceKey, [string[]]$Format) {
        [Resource]::GetInstance().Message($ResourceKey, $Format, $null, [ActionPreference]::Continue)
    }

    static [void] out([string]$ResourceKey, [string[]]$Format, [string]$Recommendments, $null) {
        [Resource]::GetInstance().Message($ResourceKey, $Format, $Recommendments, [ActionPreference]::Continue)
    }

    static [void] out([string]$ResourceKey, [string[]]$Format, [string]$Recommendments, [ActionPreference]$Action) {
        [Resource]::GetInstance().Message($ResourceKey, $Format, $Recommendments, $Action)
    }
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

    [Information]::out($Key, $Format, $Recommendments, $Action)
}

Export-ModuleMember -Function Out-Information