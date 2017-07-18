using module ..\writer\PSTrueCrypt.Writer.psm1
using module ..\writer\Verbose.psm1
using module ..\writer\Warning.psm1

#.ExternalHelp PSTrueCrypt-help.xml
function Set-CryptEnvironmentVariable
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$PathVar
    )

    [int]$Results = 0

    $Regex = "(\w+)\\?$"

    try 
    {
        [void]($PathVar -match $Regex)
        $EnvPathName = $Matches[1]
        
        $Results += [OSVerification]::($EnvPathName+"Found")

        $IsValid = Test-Path $PathVar -IsValid
        
        if($IsValid -eq $True) {
            $Results += [OSVerification]::($EnvPathName+"Valid")
        }

        $IsVerified = Test-Path $PathVar
            
        if($IsVerified -eq $True) {
            $Results += [OSVerification]::($EnvPathName+"Verified")
        }

        if(Get-OSVerificationResults $EnvPathName $Results)
        {
             Out-Verbose 'ConfirmPathVarIsValid' -Format $PathVar

            $Decision = Get-Confirmation -Message "$PathVar will be added to the 'PATH' environment variable."

            if($Decision -eq $True)
            {
                try
                {
                     Out-Verbose 'PathVarSettingAttempt' -Format $PathVar

                    [System.Environment]::SetEnvironmentVariable("Path", $env:Path +";"+ $PathVar, [EnvironmentVariableTarget]::Machine)

                     Out-Information 'ConfirmCreationOfEnvironmentVar' -Format $PathVar
                }
                catch
                {
                     Out-Error 'UnableToChangeEnvironmentVar' -Recommendment 'SecurityRecommendment' -Action Stop
                }
            }
            else
            {
                 Out-Warning 'NewEnvironmentVarCancelled'
            }  
        }
        else 
        {
             Out-Warning 'InvalidEnvironmentVarAttempt' -Format $PathVar -Action Inquire
        }
    }
    catch
    {
         Out-Warning 'InvalidEnvironmentVarAttempt' -Format $PathVar -Action Inquire
    }
}

function Start-SystemCheck
{
    [CmdletBinding()]
    Param()
    
    [int]$Results = 0;

    $Regex = "(\w+)\\?$"

    ($Env:Path).Split(';') | ForEach-Object {

        [void]($_ -match $Regex)
        $EnvPathName = $Matches[1]
        
        if(($EnvPathName -eq "TrueCrypt") -or ($EnvPathName -eq "VeraCrypt"))
        {
            $Results += [OSVerification]::($EnvPathName+"Found")

            try
            {
                 Out-Verbose 'EnvPathFoundAndWillBeTested' -Format $EnvPathName
                
                $IsValid = Test-Path $_ -IsValid
                
                if($IsValid -eq $True) {
                        $Results += [OSVerification]::($EnvPathName+"Valid")

                    $IsVerified = Test-Path $_
                    
                    if($IsVerified -eq $True) {
                        $Results += [OSVerification]::($EnvPathName+"Verified")
                    }
                }
            }
            # should be safe to swallow.  any discrepanceis will result in the Get-OSVerificationResults call...
            catch{ }

            if(Get-OSVerificationResults $EnvPathName $Results)
            {
                 Out-Verbose 'EnvPathSuccessfullyTested' -Format $EnvPathName
            }
            else
            {
                 Out-Warning 'EnvironmentVarPathFailed' -Format {$_}
                 Out-Warning 'EnvironmentVarRecommendation' -Format {$EnvPathName,$EnvPathName}
                 Out-Warning 'EnvironmentVarRecommendationExample' -Format $EnvPathName
                 Out-Warning 'EnvironmentVarRecommendation2'
            }
        }
    }
}

# internal function
function Get-OSVerificationResults
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$EnvPathName,

        [Parameter(Mandatory = $True, Position = 2)]
        [int]$Results,

        [ValidateSet("Found", "Valid", "Verified", "Success")]
        [string]$ResultStep = "Success"
    )

    try 
    {
        ([OSVerification]::($EnvPathName+$ResultStep) -band $Results)/[OSVerification]::($EnvPathName+$ResultStep) -eq $True
    }
    catch
    {
        $False
    }
}