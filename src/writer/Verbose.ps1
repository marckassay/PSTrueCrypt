using namespace 'System.Resources'

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
}

class Verbose
{
    static [void] out([string]$ResourceKey) {
        [Resource]::GetInstance().Message($ResourceKey, $null)
    }

    static [void] out([string]$ResourceKey, [string[]]$Format) {
        [Resource]::GetInstance().Message($ResourceKey, $Format)
    }
}