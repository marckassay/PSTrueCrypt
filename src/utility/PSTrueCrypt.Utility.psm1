using module ..\Writer\PSTrueCrypt.Writer.psm1
using module .\Container.psm1
using module ..\Storage\PSTrueCrypt.Storage.psm1

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

function Start-SystemCheck
{
    [CmdletBinding()]
    Param()
    
    Add-Type -AssemblyName System.Windows.Forms

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
Export-ModuleMember -Function Start-SystemCheck

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
Export-ModuleMember -Function Set-CryptEnvironmentVariable

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
Export-ModuleMember -Function Edit-HistoryFile

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
Export-ModuleMember -Function Get-Confirmation


# internal function
# ref: http://www.jonathanmedd.net/2014/01/testing-for-admin-privileges-in-powershell.html
function Test-IsAdmin 
{
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}
Export-ModuleMember -Function Test-IsAdmin 

function Restart-LogicalDiskCheck
{
    # Enumerates thru all containers that have 'IsMounted' set to true and who's LastMountedUri drive is now
    # not attached.  If so, this will set the container's IsMounted to false...
    Get-RegistrySubKeys -FilterScript { [bool]($_.getValue('IsMounted')) -eq $True -and `
                             ((Test-Path ($_.getValue('LastMountedUri')+':')) -eq $False) 
                        } | Write-Container -IsMounted:$False
}
Export-ModuleMember -Function Restart-LogicalDiskCheck


function New-Container
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True, Position = 1,
         HelpMessage="Give a name for this container.")]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $True, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]$Location,

        [Parameter(Mandatory = $True, Position = 3)]
        [ValidatePattern("^[a-zA-Z]$")]
        [string]$MountLetter,

        [Parameter(Mandatory = $True, Position = 4)]
        [ValidateSet("TrueCrypt", "VeraCrypt")]
        [string]$Product,

        [switch]$IsMounted,

        [switch]$Timestamp
    )

    $Container = [Container]::new()
    $Container.Start()
    $Container.Name($Name)
    $Container.Location($Location)
    $Container.MountLetter($MountLetter)
    $Container.Product($Product)
    $Container.IsMounted($IsMounted)
    $Container.Timestamp($Timestamp)
    $Container.SetLastActivity((Get-Date))
    $Container.Complete()
}
Export-ModuleMember -Function New-Container

function Write-Container
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $False, ValueFromPipeline = $True)]
        [AllowNull()]
        [PsObject]$RegistrySubKey,

        [Parameter(Mandatory = $False, 
         HelpMessage="Enter the generated Id for this container.")]
        [ValidateNotNullOrEmpty()]
        [string]$KeyId,

        [Parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()]
        [string]$Location,

        [Parameter(Mandatory = $False)]
        [ValidatePattern("^[a-zA-Z]$")]
        [string]$MountLetter,

        [Parameter(Mandatory = $False)]
        [ValidateSet("TrueCrypt", "VeraCrypt")]
        [string]$Product,

        [Parameter(Mandatory = $False)]
        [ValidatePattern("^[a-zA-Z]$")]
        [string]$LastMountedUri,

        [Parameter(Mandatory = $False)]
        [switch]$IsMounted,

        [switch]$Timestamp,

        [switch]$SilenceActivity,

        [switch]$ContinueTransaction
    )

    $Container = [Container]::new()
    if($RegistrySubKey) {
        $Container.SubKey = $RegistrySubKey
    } elseif ($KeyId) {
        $Container.KeyId = $KeyId
    }

    $Container.Start()

    if($Name) {
        $Container.Name($Name)
    }
    
    if($Location) {
        $Container.Location($Location)
    }

    if($MountLetter) {
        $Container.MountLetter($MountLetter)
    }
    
    if($Product) {
        $Container.Product($Product)
    }
    
    if($Timestamp) {
        $Container.Timestamp($Timestamp)
    }
    
    if($IsMounted) {
        $Container.IsMounted($IsMounted)
    }

    # if this is switched (True), that means we dont want to record this activity
    if($NoActivity -eq $False) {
        $Container.LastActivity( (Get-Date) )
    }

    # if this is switched (True), that means we dont want to complete this transaction just yet.
    if($ContinueTransaction -eq $False) {
        $Container.Complete()
    }
}
Export-ModuleMember -Function Write-Container

function Read-Container
{
    [CmdletBinding()]
    [OutputType([HashTable])]
    Param
    (
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [AllowNull()]
        [PsObject]$RegistrySubKey
    )

    begin
    {
        if($SUT -eq $False) {
            Push-Location
            
            Set-Location -Path HKCU:\SOFTWARE\PSTrueCrypt
            
            Start-Transaction
        }
    }

    process 
    {
        $Container = [Container]::new()
        $Container.SubKey = $RegistrySubKey
        <#
        the hashtable keys are the following:
            KeyId         
            KeyPath    
            Name       
            Location   
            MountLetter
            Product    
            Timestamp  
            IsMounted  
            LastActivity
        #>
        $HashTable = $Container.GetHashTable()
    }

    end
    {
        if($SUT -eq $False) {
            Pop-Location

            Complete-Transaction
        }

        $HashTable
    }
}
Export-ModuleMember -Function Read-Container

function Get-DynamicParameterValues
{
    $ContainerNames = Get-RegistrySubKeys | Get-SubKeyNames

    $ParamAttrib = New-Object ParameterAttribute
    $ParamAttrib.Mandatory = $True
    $ParamAttrib.Position = 0

    $AttribColl = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
    $AttribColl.Add((New-Object ValidateSetAttribute($ContainerNames)))
    $AttribColl.Add($ParamAttrib)

    $RuntimeParam = New-Object RuntimeDefinedParameter('Name', [string], $AttribColl)
    $RuntimeParamDic = New-Object RuntimeDefinedParameterDictionary
    $RuntimeParamDic.Add('Name', $RuntimeParam)

    return $RuntimeParamDic
}
Export-ModuleMember -Function Get-DynamicParameterValues