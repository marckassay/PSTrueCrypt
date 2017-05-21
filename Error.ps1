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

    [System.Resources.ResXResourceSet]$ErrorResourceSet

    ErrorMessage(
        [string]$Key, 
        [string]$Recommendments, 
        [string[]]$Format, 
        [System.Management.Automation.ActionPreference]$Action, 
        [string]$ErrorId)
    {
        if(!$this.ErrorResourceSet) {
            $this.ErrorResourceSet = New-Object -TypeName 'System.Resources.ResXResourceSet' -ArgumentList $PSScriptRoot"\resx\Error.resx"
        }
        
        $Message = $this.ErrorResourceSet.GetString($Key)
        
        $Recommendment = ''
        if($Recommendments) {
            $Recommendment = $this.ErrorResourceSet.GetString($Recommendments)
        }

        if($Format) {
            $Message = ($Message+" -f "+$Format)
        }

        if(!$Action) {
            $Action = [System.Management.Automation.ActionPreference]::Continue
        }

        Write-Error -Message $Message -ErrorId $ErrorId -ErrorAction $Action -RecommendedAction $Recommendment
    }
}

class Error
{
    static [void] out([string]$ResourceKey) {
        [Resource]::GetInstance().ErrorMessage($ResourceKey, $null, $null, [ActionPreference]::Continue, [Error]::GetErrorId($ResourceKey))
    }
    
    static [void] out([string]$ResourceKey, [string]$Recommendment) {
        [Resource]::GetInstance().ErrorMessage($ResourceKey, $Recommendment, $null, [ActionPreference]::Continue, [Error]::GetErrorId($ResourceKey))
    }

    static [void] out([string]$ResourceKey, [string]$Recommendment, [string[]]$Format) {
        [Resource]::GetInstance().ErrorMessage($ResourceKey, $Recommendment, $Format, [ActionPreference]::Continue, [Error]::GetErrorId($ResourceKey))
    }

    static [void] out([string]$ResourceKey, [string]$Recommendment, [string[]]$Format, [ActionPreference]$Action)
    {
        [Resource]::GetInstance().ErrorMessage($ResourceKey, $Recommendment, $Format, $Action, [Error]::GetErrorId($ResourceKey))
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