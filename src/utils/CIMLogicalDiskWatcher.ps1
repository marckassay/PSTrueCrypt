function Start-CIMLogicalDiskWatch
{
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$SubKeyName
    )
    
    $CreationFilter = "SELECT * FROM CIM_InstCreation WITHIN 1 WHERE TargetInstance ISA 'CIM_LogicalDisk'"

    Register-CimIndicationEvent -Query $CreationFilter -Action { 

        $Event.MessageData.KeyId # f9910b39-dc58-4a34-be4b-c4b61df3799b
        $Event.SourceIdentifier # PSTrueCrypt_Creation_Watcher
        $Event.TimeGenerated # 6/21/2017 5:10:15 PM

        $KeyId = $Event.MessageData.KeyId

        Write-Host " ----> "$KeyId

        Set-PSTrueCryptContainer -SubKeyName $KeyId -IsMounted $True
    
    } -SourceIdentifier "PSTrueCrypt_Creation_Watcher" -MessageData @{ KeyId=$SubKeyName } -MaxTriggerCount 1 -OperationTimeoutSec 30


    $DeletionFilter = "SELECT * FROM CIM_InstDeletion WITHIN 3 WHERE TargetInstance ISA 'CIM_LogicalDisk'"

    Register-CimIndicationEvent -Query $DeletionFilter -Action { 

        Set-PSTrueCryptContainer -SubKeyName $Event.MessageData.KeyId -IsMounted $False
    
    } -SourceIdentifier "PSTrueCrypt_Deletion_Watcher" -MessageData @{ KeyId=$SubKeyName } -MaxTriggerCount 1 
}