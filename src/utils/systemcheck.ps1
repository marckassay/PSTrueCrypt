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
    [Warning]::out('InvalidEnvironmentVarAttempt', $PathVar, [ActionPreference]::Inquire)
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
            [Verbose]::out('ConfirmPathVarIsValid', {$PathVar})

            $Decision = Get-Confirmation -Message "$PathVar will be added to the 'PATH' environment variable."

            if($Decision -eq $True)
            {
                try
                {
                    [Verbose]::out('PathVarSettingAttempt', {$PathVar})

                    [System.Environment]::SetEnvironmentVariable("Path", $env:Path +";"+ $PathVar, [EnvironmentVariableTarget]::Machine)

                    [Information]::out('ConfirmCreationOfEnvironmentVar', {$PathVar})
                }
                catch
                {
                    [Error]::out('UnableToChangeEnvironmentVar', 'SecurityRecommendment', $null, [ActionPreference]::Stop)
                }
            }
            else
            {
                [Warning]::out('NewEnvironmentVarCancelled')
            }  
        }
        else 
        {
            [Warning]::out('InvalidEnvironmentVarAttempt', $PathVar, [ActionPreference]::Inquire)
        }
    }
    catch
    {
        [Warning]::out('InvalidEnvironmentVarAttempt', {$PathVar}, [ActionPreference]::Inquire)
    }
}

function Start-SystemCheck
{
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
                [Verbose]::out('EnvPathFoundAndWillBeTested', {$EnvPathName})
                
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
                [Verbose]::out('EnvPathSuccessfullyTested', {$EnvPathName})
            }
            else
            {
                [Warning]::out('EnvironmentVarPathFailed', {$_})
                [Warning]::out('EnvironmentVarRecommendation', {$EnvPathName,$EnvPathName})
                [Warning]::out('EnvironmentVarRecommendationExample', {$EnvPathName})
                [Warning]::out('EnvironmentVarRecommendation2')
            }
        }
    }
}

# internal function
function Get-OSVerificationResults
{
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