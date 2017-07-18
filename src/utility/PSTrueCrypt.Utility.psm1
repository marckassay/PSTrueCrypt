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

    $Container = [Container]::GetInstance()
    $Container.Name($Name)
    $Container.Location($Location)
    $Container.MountLetter($MountLetter)
    $Container.Product($Product)
    $Container.IsMounted($IsMounted)
    $Container.Timestamp($Timestamp)
    $Container.Complete()
}

function Write-Container
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True, Position = 1, 
         HelpMessage="Enter the generated Id for this container.")]
        [ValidateNotNullOrEmpty()]
        [string]$Id,

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
        [bool]$Timestamp,

        [Parameter(Mandatory = $False)]
        [bool]$IsMounted,

        [switch]$NoActivity,

        [switch]$ContinueTransaction
    )

    $Container = [Container]::GetInstance()
    $Container.Id = Id

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
        $Container = [Container]::GetInstance()
        $Container.SubKey = $RegistrySubKey

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

Export-ModuleMember -Function New-Container
Export-ModuleMember -Function Write-Container
Export-ModuleMember -Function Read-Container

function Start-CimLogicalDiskWatch
{
    Param
    (
        [Parameter(Mandatory = $True, Position = 1, ValueFromPipelineByPropertyName=$True)]
        [AllowNull()]
        [Alias("PSChildName")]
        [String]$SubKeyName,

        [ValidateSet("Creation","Deletion")]
        [Parameter(Mandatory = $True, Position = 2)]
        [String]$InstanceType
    )
    
    begin
    {

    }

    process
    {
        if($SubKeyName) {
            $UniqueLabel = $SubKeyName.Substring(0,8)
        
            Stop-CimLogicalDiskWatch $UniqueLabel $InstanceType

            $SourceId = "PSTrueCrypt_"+$InstanceType+"_Watcher_"+$UniqueLabel

            $Filter = "SELECT * FROM CIM_Inst"+$InstanceType+" WITHIN 1 WHERE TargetInstance ISA 'CIM_LogicalDisk'"

            # TODO: temp hack until I can retrieve DeviceID inside the Action block for Register-CimIndicationEvent.  this
            # problematic if the mounting executing changes uri from MountedLetter.  For instance if MountedLetter is already
            # in use and it changes uri.
            $PredeterminedDeviceId = (Get-PSTrueCryptContainers -FilterScript {$_.PSChildName -eq $SubKeyName} | Get-ItemProperty -Name MountLetter).MountLetter

            $void = Register-CimIndicationEvent -Query $Filter -Action { 
                $KeyId = $Event.MessageData.KeyId # f9910b39-dc58-4a34-be4b-c4b61df3799b
                $DeviceId = $Event.MessageData.LastMountedUri
                $IsMounted = $Event.SourceIdentifier.Contains('Creation') # PSTrueCrypt_Creation_Watcher_f9910b39
                $LastActivity = $Event.TimeGenerated # 6/21/2017 5:10:15 PM
                #TODO:  I no longer seem to be able to have the debugger break in this block.
                # I would like to get the DeviceId (Get-CimInstance -ClassName CIM_LogicalDisk) from this instance
                <#
                $a= $Event
                $b= $EventSubscriber
                $c= $Sender
                $d= $SourceEventArgs
                $e= $SourceArgs 
                Write-Host ($a | Format-List -Force | Out-String)
                Write-Host ($b | Format-List -Force | Out-String)
                Write-Host ($c | Format-List -Force | Out-String)
                Write-Host ($d | Format-List -Force | Out-String)
                Write-Host ($e | Format-List -Force | Out-String)
                #>
                Set-PSTrueCryptContainer -SubKeyName $KeyId -IsMounted $IsMounted -LastActivity $LastActivity -LastMountedUri $DeviceId
            } -SourceIdentifier $SourceId -MessageData @{ KeyId=$SubKeyName; LastMountedUri=$PredeterminedDeviceId } -MaxTriggerCount 1 -OperationTimeoutSec 35
        }
    }

    end
    {

    }
}
function Stop-CimLogicalDiskWatch
{
    Param
    (
        [Parameter(Mandatory = $False, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$SubKeyName,

        [Parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()]
        [string]$UniqueLabel,

        [ValidateSet("Creation","Deletion")]
        [Parameter(Mandatory = $True, Position = 2)]
        [String]$InstanceType
    )

    if($SubKeyName) {
        $UniqueLabel = $SubKeyName.Substring(0,8)
    }
    
    $SourceId = "PSTrueCrypt_"+$InstanceType+"_Watcher_"+$UniqueLabel

    Unregister-Event -SourceIdentifier $SourceId -ErrorAction Ignore
    Remove-Event -SourceIdentifier $SourceId -ErrorAction Ignore
}