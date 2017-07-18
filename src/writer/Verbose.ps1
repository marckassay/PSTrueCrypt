using namespace 'System.Resources'

class Verbose
{
    static [Verbose] $instance

    static [Verbose] GetInstance()
    {
        if ([Verbose]::instance -eq $null) {
            [Verbose]::instance = [Verbose]::new()
        }

        return [Verbose]::instance
    }

    $ResourceSet

    Message(
        [string]$Key, 
        [string[]]$Format)
    {
        if(!$this.ResourceSet) {
            $this.ResourceSet = New-Object -TypeName 'System.Resources.ResXResourceSet' -ArgumentList $PSScriptRoot"\..\..\resx\Verbose.resx"
        }
        
        $Message = $this.ResourceSet.GetString($Key)

        if($Format) {
            $Message = ($Message -f $Format)
        }

        Write-Verbose -Message $Message
    }

    [void] out([string]$ResourceKey) {
        $this.Message($ResourceKey, $null)
    }

    [void] out([string]$ResourceKey, [string[]]$Format) {
        $this.Message($ResourceKey, $Format)
    }
}