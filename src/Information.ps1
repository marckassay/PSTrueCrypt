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

    [System.Resources.ResXResourceSet]$ResourceSet

    Message(
        [string]$Key, 
        [string[]]$Format, 
        [string]$Recommendments, 
        [System.Management.Automation.ActionPreference]$Action)
    {
        if(!$this.ResourceSet) {
            $this.ResourceSet = New-Object -TypeName 'System.Resources.ResXResourceSet' -ArgumentList $PSScriptRoot"\..\resx\Information.resx"
        }
        
        $Message = $this.ResourceSet.GetString($Key)

        $Recommendment = ''
        if($Recommendments) {
            $Recommendment = $this.ResourceSet.GetString($Recommendments)
        }

        if($Format) {
            $Message = ($Message+" -f "+$Format)
        }

        if(!$Action) {
            $Action = [ActionPreference]::Continue
        }

        Write-Information -MessageData $Message -InformationAction $Action -RecommendedAction $Recommendments
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