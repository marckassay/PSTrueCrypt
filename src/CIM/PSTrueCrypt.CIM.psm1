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
    
    if($KeyId) {
        $UniqueLabel = $KeyId.Substring(0,8)

        Stop-CimLogicalDiskWatch $UniqueLabel $InstanceType

        $Filter = "SELECT * FROM CIM_Inst"+$InstanceType+" WITHIN 1 WHERE TargetInstance ISA 'CIM_LogicalDisk'"
        $Action = { 
            $ReturnedKeyId = $Event.MessageData.KeyId # f9910b39-dc58-4a34-be4b-c4b61df3799b
            $IsMounted = $Event.SourceIdentifier.Contains('Creation') # PSTrueCrypt_Creation_Watcher_f9910b39
            $DeviceId = $Event.MessageData.LastMountedUri # D
            #$LastActivity = $Event.TimeGenerated # 6/21/2017 5:10:15 PM

            $StorageLocation = 'HKCU:\SOFTWARE\PSTrueCrypt'
            Start-Transaction
            Push-Location
            Set-Location -Path $StorageLocation

            Get-RegistrySubKeys -FilterScript { $_.PSChildName -eq $ReturnedKeyId } | Write-Container -IsMounted $IsMounted -LastMountedUri $DeviceId

            Pop-Location
            Complete-Transaction
        }

        $SourceId = "PSTrueCrypt_"+$InstanceType+"_Watcher_"+$UniqueLabel

        # TODO: temp hack until I can retrieve DeviceID inside the Action block for Register-CimIndicationEvent.  this
        # problematic if the mounting executing changes uri from MountedLetter.  For instance if MountedLetter is already
        # in use and it changes uri.
        $PredeterminedDeviceId = (Get-RegistrySubKeys -FilterScript {$_.PSChildName -eq $KeyId} | Read-Container).MountLetter

        Register-CimIndicationEvent -Query $Filter `
                                    -Action $Action `
                                    -SourceIdentifier $SourceId `
                                    -MessageData @{ KeyId=$KeyId; LastMountedUri=$PredeterminedDeviceId } `
                                    -MaxTriggerCount 1 `
                                    -OperationTimeoutSec 35 | Out-Null
    }
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

    Unregister-Event -SourceIdentifier $SourceId -ErrorAction Ignore
    Remove-Event -SourceIdentifier $SourceId -ErrorAction Ignore
}

Export-ModuleMember -Function Start-CimLogicalDiskWatch
Export-ModuleMember -Function Stop-CimLogicalDiskWatch