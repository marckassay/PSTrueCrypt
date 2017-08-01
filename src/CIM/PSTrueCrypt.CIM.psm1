using module ..\Storage\PSTrueCrypt.Storage.psm1

function Start-CimLogicalDiskWatch
{
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [Alias("PSChildName")]
        [String]$KeyId,

        [ValidateSet("Creation","Deletion")]
        [Parameter(Mandatory = $True, Position = 2)]
        [String]$InstanceType
    )
    
    begin
    {
        Get-CallName -mess "Alice"

    }

    process
    {
        if($KeyId) {
            $UniqueLabel = $KeyId.Substring(0,8)
        Get-CallName -mess "Bob"
            Stop-CimLogicalDiskWatch $UniqueLabel $InstanceType

            $SourceId = "PSTrueCrypt_"+$InstanceType+"_Watcher_"+$UniqueLabel

            $Filter = "SELECT * FROM CIM_Inst"+$InstanceType+" WITHIN 1 WHERE TargetInstance ISA 'CIM_LogicalDisk'"

            # TODO: temp hack until I can retrieve DeviceID inside the Action block for Register-CimIndicationEvent.  this
            # problematic if the mounting executing changes uri from MountedLetter.  For instance if MountedLetter is already
            # in use and it changes uri.
            $PredeterminedDeviceId = (Get-RegistrySubKeys -FilterScript {$_.PSChildName -eq $KeyId} | Read-Container).MountLetter
#Get-RegistrySubKeys -FilterScript {$_.PSChildName -eq $KeyId} | Write-Container -FilterScript { $_.PSChildName -eq $ReturnedKeyId } 
Get-CallName -mess "Charles"
            $Job = Register-CimIndicationEvent -Query $Filter -Action { 
                $ReturnedKeyId = $Event.MessageData.KeyId # f9910b39-dc58-4a34-be4b-c4b61df3799b
               # $DeviceId = $Event.MessageData.LastMountedUri
               # $IsMounted = $Event.SourceIdentifier.Contains('Creation') # PSTrueCrypt_Creation_Watcher_f9910b39
                #$LastActivity = $Event.TimeGenerated # 6/21/2017 5:10:15 PM
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
                #Write-Host "Writae-Container -KeyId $ReturnedKeyId -IsMounted $IsMounted -LastMountedUri $DeviceId "

               # $ReturnedKeyId | Read-Container
               # Write-Information -MessageData "Results from Get-RegistrySubKeys..TTT. $TTT" -InformationAction Continue
               #$TTT = Get-RegistrySubKeys -FilterScript { $_.PSChildName -eq $ReturnedKeyId }
               # Write-Container -FilterScript { $ReturnedKeyId }

               Get-CallName -mess "Marc"
               # Write-Information -MessageData "Calling Write-Container..." -InformationAction Continue
               # Stop-CimLogicalDiskWatch

            } -SourceIdentifier $SourceId -MessageData @{ KeyId=$KeyId; LastMountedUri=$PredeterminedDeviceId } -MaxTriggerCount 1 -OperationTimeoutSec 35 
        }
    }

    end
    { 

    }
}

function Get-CallName
{

    Param
    (
        [Parameter(Mandatory = $False, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$mess
    )

    Write-Host "Call who: $mess"
}

function Stop-CimLogicalDiskWatch
{
    Param
    (
        [Parameter(Mandatory = $False, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$KeyId,

        [Parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()]
        [string]$UniqueLabel,

        [ValidateSet("Creation","Deletion")]
        [Parameter(Mandatory = $True, Position = 2)]
        [String]$InstanceType
    )

    if($KeyId) {
        $UniqueLabel = $KeyId.Substring(0,8)
    }
    
    $SourceId = "PSTrueCrypt_"+$InstanceType+"_Watcher_"+$UniqueLabel
    Write-Host $SourceId
    Unregister-Event -SourceIdentifier $SourceId -ErrorAction Ignore
    Remove-Event -SourceIdentifier $SourceId -ErrorAction Ignore
}

Export-ModuleMember -Function Start-CimLogicalDiskWatch
Export-ModuleMember -Function Stop-CimLogicalDiskWatch
Export-ModuleMember -Function Get-CallName