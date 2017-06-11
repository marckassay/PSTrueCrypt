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
        [string]$Recommendments, 
        [string[]]$Format, 
        [System.Management.Automation.ActionPreference]$Action, 
        [string]$ErrorId)
    {
        if(!$this.ResourceSet) {
            $this.ResourceSet = New-Object -TypeName 'System.Resources.ResXResourceSet' -ArgumentList $PSScriptRoot"\..\..\resx\Error.resx"
        }
        
        $Message = $this.ResourceSet.GetString($Key)
        
        $Recommendment = ''
        if($Recommendments) {
            $Recommendment = $this.ResourceSet.GetString($Recommendments)
        }

        if($Format) {
            $Message = ($Message -f $Format)
        }

        Write-Error -Message $Message -ErrorId $ErrorId -ErrorAction $Action -RecommendedAction $Recommendment
    }
}

class Error
{
    static [void] out([string]$ResourceKey) {
        [Resource]::GetInstance().Message($ResourceKey, $null, $null, [ActionPreference]::Continue, [Error]::GetErrorId($ResourceKey))
    }
    
    static [void] out([string]$ResourceKey, [string]$Recommendment) {
        [Resource]::GetInstance().Message($ResourceKey, $Recommendment, $null, [ActionPreference]::Continue, [Error]::GetErrorId($ResourceKey))
    }

    static [void] out([string]$ResourceKey, [string]$Recommendment, [string[]]$Format) {
        [Resource]::GetInstance().Message($ResourceKey, $Recommendment, $Format, [ActionPreference]::Continue, [Error]::GetErrorId($ResourceKey))
    }

    static [void] out([string]$ResourceKey, [string]$Recommendment, [string[]]$Format, [ActionPreference]$Action)
    {
        [Resource]::GetInstance().Message($ResourceKey, $Recommendment, $Format, $Action, [Error]::GetErrorId($ResourceKey))
    }

    #http://jongurgul.com/blog/get-stringhash-get-filehash/ 
    hidden static [string] GetErrorId([String]$Key)
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
    
    [Error]::out($Key, $Recommendment, $Format, $Action)
}

Export-ModuleMember -Function Out-Error