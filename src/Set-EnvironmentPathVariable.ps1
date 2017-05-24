#.ExternalHelp PSTrueCrypt-help.xml
function Set-EnvironmentPathVariable
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
        ($PathVar -match $Regex)
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
            [Warning]::out('InvalidEnvironmentVarAttempt', {$PathVar}, [ActionPreference]::Inquire)
        }
    }
    catch
    {
        [Warning]::out('InvalidEnvironmentVarAttempt', {$PathVar}, [ActionPreference]::Inquire)
    }
}