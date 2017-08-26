using namespace 'System.Resources'
using namespace 'System.Management.Automation'

class Warning
{
    static [Warning] $instance

    static [Warning] GetInstance()
    {
        if ([Warning]::instance -eq $null) {
            [Warning]::instance = [Warning]::new()
        }

        return [Warning]::instance
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

    [void] out([string]$ResourceKey) {
        $this.Message($ResourceKey, $null, [ActionPreference]::Continue)
    }

    [void] out([string]$ResourceKey, [string[]]$Format) {
        $this.Message($ResourceKey, $Format, [ActionPreference]::Continue)
    }

    [void] out([string]$ResourceKey, [string[]]$Format, [ActionPreference]$Action)
    {
        $this.Message($ResourceKey, $Format, $Action)
    }
}