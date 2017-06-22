function Start-CIMLogicalDiskWatch
{
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$SubKeyName
    )

    # get the first octet to be added to the SourceIdentifier.  this is needed
    # for concurrent calls to Start-CIMLogicalDiskWatch
    $ShortName = $SubKeyName.Substring(0,8)

    $CreationFilter = "SELECT * FROM CIM_InstCreation WITHIN 1 WHERE TargetInstance ISA 'CIM_LogicalDisk'"

    $void = Register-CimIndicationEvent -Query $CreationFilter -Action { 

        #$Event.MessageData.KeyId # f9910b39-dc58-4a34-be4b-c4b61df3799b
        #$Event.SourceIdentifier # PSTrueCrypt_Creation_Watcher
        #$Event.TimeGenerated # 6/21/2017 5:10:15 PM

        $KeyId = $Event.MessageData.KeyId
        $LastActivity = $Event.TimeGenerated

        Set-PSTrueCryptContainer -SubKeyName $KeyId -IsMounted $True -LastActivity $LastActivity
    
    } -SourceIdentifier "PSTrueCrypt_Creation_Watcher_$ShortName" -MessageData @{ KeyId=$SubKeyName } -MaxTriggerCount 1 -OperationTimeoutSec 30


    $DeletionFilter = "SELECT * FROM CIM_InstDeletion WITHIN 3 WHERE TargetInstance ISA 'CIM_LogicalDisk'"

    $void = Register-CimIndicationEvent -Query $DeletionFilter -Action { 

        $KeyId = $Event.MessageData.KeyId
        $LastActivity = $Event.TimeGenerated

        Set-PSTrueCryptContainer -SubKeyName $KeyId -IsMounted $False -LastActivity $LastActivity
    
    } -SourceIdentifier "PSTrueCrypt_Deletion_Watcher_$ShortName" -MessageData @{ KeyId=$SubKeyName } -MaxTriggerCount 1
}