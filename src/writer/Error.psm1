using namespace 'System.Resources'
using namespace 'System.Management.Automation'

class Error
{
    static [Error] $instance

    static [Error] GetInstance()
    {
        if ([Error]::instance -eq $null) {
            [Error]::instance = [Error]::new()
        }

        return [Error]::instance
    }

    $ResourceSet

    Message(
        [string]$Key, 
        [string]$Recommendments, 
        [string[]]$Format, 
        [System.Management.Automation.ActionPreference]$Action, 
        [string]$ErrorId)
    {
        if(!$this.ResourceSet) {
            $this.ResourceSet = New-Object -TypeName 'System.Resources.ResXResourceSet' -ArgumentList $PSScriptRoot"\..\..\resx\Error.resx"
        }
        
        $Msg = $this.ResourceSet.GetString($Key)
        
        $Recommendment = ''
        if($Recommendments) {
            $Recommendment = $this.ResourceSet.GetString($Recommendments)
        }

        if($Format) {
            $Msg = ($Msg -f $Format)
        }

        Write-Error -Message $Msg -ErrorId $ErrorId -ErrorAction $Action -RecommendedAction $Recommendment
    }

    [void] out([string]$ResourceKey) {
        $this.Message($ResourceKey, $null, $null, [ActionPreference]::Continue, $this.GetErrorId($ResourceKey))
    }

    [void] out([string]$ResourceKey, [string]$Recommendment) {
        $this.Message($ResourceKey, $Recommendment, $null, [ActionPreference]::Continue, $this.GetErrorId($ResourceKey))
    }

    [void] out([string]$ResourceKey, [string]$Recommendment, [string[]]$Format) {
        $this.Message($ResourceKey, $Recommendment, $Format, [ActionPreference]::Continue, $this.GetErrorId($ResourceKey))
    }

    [void] out([string]$ResourceKey, [string]$Recommendment, [string[]]$Format, [ActionPreference]$Action) {
        $this.Message($ResourceKey, $Recommendment, $Format, $Action, $this.GetErrorId($ResourceKey))
    }

    #http://jongurgul.com/blog/get-stringhash-get-filehash/ 
    hidden [string] GetErrorId([String]$Key)
    {
        [String]$HashName = "MD5"

        $StringBuilder = New-Object System.Text.StringBuilder

        [void]$StringBuilder.Append('E-')

        [System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Key)) | ForEach-Object { 
                [void]$StringBuilder.Append($_.ToString("x2"))
        } 

        return $StringBuilder.ToString(0,8).ToUpperInvariant()
    }
}