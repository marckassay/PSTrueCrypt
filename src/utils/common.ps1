using module ..\writer\Error.psm1
using module .\UtilTimer.psm1

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
    Unregister-Event -SourceIdentifier LogicalDiskCheck.Timer -ErrorAction Ignore
    Register-ObjectEvent -InputObject (New-Timer) -EventName Elapsed -SourceIdentifier 'LogicalDiskCheck.Timer' -Action {
Write-Host ">>>pulse<<<"
        # TODO: we should check for 'Deletion' instances too.  Perhaps add a passthru param 
        # for Start-CIMLogicalDiskWatch and pipe another call to it.
        # Get containers that have a 'mounted' status AND have been mounted more then 3 minutes...  -gt ((Get-Date) - (New-TimeSpan -Minutes 3))
       PSTrueCrypt\Get-MountedContainers -FilterScript { ($_.GetValue('IsMounted') -eq $True) -AND (Get-Date $_.GetValue('LastActivity')) -lt ((Get-Date) - (New-TimeSpan -Minutes 3)) } | ForEach-Object {
            $_.LastMountedUri 
       }
    }
    
   # Start-Timer
}