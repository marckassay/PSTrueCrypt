using module ..\writer\PSTrueCrypt.Writer.psm1

enum OSVerification {
    TrueCryptFound = 1
    VeraCryptFound = 2
                
    TrueCryptValid = 4
    VeraCryptValid = 8
     
    TrueCryptVerified = 16
    VeraCryptVerified = 32

    TrueCryptSuccess = 21
    VeraCryptSuccess = 42
}

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
    
    Add-Type -AssemblyName System.Windows.Forms

    Set-Alias -Name mt -Value Mount-TrueCrypt
    Set-Alias -Name dmt -Value Dismount-TrueCrypt
    Set-Alias -Name dmt* -Value Dismount-TrueCryptForceAll

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

#internal function
function Edit-HistoryFile
{
    try
    {
        $PSHistoryFilePath = (Get-PSReadlineOption | Select-Object -ExpandProperty HistorySavePath)
        $PSHistoryTempFilePath = $PSHistoryFilePath+".tmp"

        Get-Content -Path $PSHistoryFilePath | ForEach-Object { $_ -replace "-KeyfilePath.*(?<!Mount\-TrueCrypt|mt)", "-KeyfilePath X:\XXXXX\XXXXX\XXXXX"} | Set-Content -Path $PSHistoryTempFilePath

        Copy-Item -Path $PSHistoryTempFilePath -Destination $PSHistoryFilePath -Force

        Remove-Item -Path $PSHistoryTempFilePath -Force
    }
    catch
    {
        Out-Error 'UnableToRedact'
        Out-Error 'Genaric' -Format $PSHistoryFilePath -Action Inquire
    }
}


# internal function
# ref: http://stackoverflow.com/a/24649481
function Get-Confirmation
{
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$Message
    )
    
    $Question = 'Are you sure you want to proceed?'

    $Choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
    $Choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList "&Yes"))
    $Choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList "&No"))

    [bool]$Decision = !($Host.UI.PromptForChoice($Message, $Question, $Choices, 1))
    
    $Decision
}


# internal function
# ref: http://www.jonathanmedd.net/2014/01/testing-for-admin-privileges-in-powershell.html
function Test-IsAdmin 
{
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

function Restart-LogicalDiskCheck
{
    # Enumerates thru all containers that have 'IsMounted' set to true and who's LastMountedUri drive is now
    # not attached.  If so, this will set the container's IsMounted to false...
    Get-PSTrueCryptContainers -FilterScript { $_.getValue('IsMounted') -eq $True -and ((Test-Path ($_.getValue('LastMountedUri')+':')) -eq $False) } | ForEach-Object {
        Set-PSTrueCryptContainer -SubKeyName $_.PSChildName -IsMounted $False -LastActivity (Get-Date)
    }
}