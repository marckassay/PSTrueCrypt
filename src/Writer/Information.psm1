using namespace 'System.Resources'
using namespace 'System.Management.Automation'

class Information
{
    static [Information] $instance

    static [Information] GetInstance()
    {
        if ([Information]::instance -eq $null) {
            [Information]::instance = [Information]::new()
        }

        return [Information]::instance
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

    [void] out([string]$ResourceKey) {
        $this.Message($ResourceKey, $null, $null, [ActionPreference]::Continue)
    }

    [void] out([string]$ResourceKey, [string[]]$Format) {
        $this.Message($ResourceKey, $Format, $null, [ActionPreference]::Continue)
    }

    [void] out([string]$ResourceKey, [string[]]$Format, [string]$Recommendments, $null) {
        $this.Message($ResourceKey, $Format, $Recommendments, [ActionPreference]::Continue)
    }

    [void] out([string]$ResourceKey, [string[]]$Format, [string]$Recommendments, [ActionPreference]$Action) {
        $this.Message($ResourceKey, $Format, $Recommendments, $Action)
    }
}