function Start-Watch
{
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$SubKeyName
    )

    $CreationFilter = "SELECT * FROM CIM_InstCreation WITHIN 1 WHERE TargetInstance ISA 'CIM_LogicalDisk'"

    Register-CimIndicationEvent -Query $CreationFilter -Action { 

        Write-Host "Creation >>>  <<<"
        Write-Host "  -"$Event.toString() # System.Management.Automation.PSEventArgs
        Write-Host "  -"$Event.EventIdentifier # 1
        Write-Host "  -"$Event.MessageData.Container # f9910b39-dc58-4a34-be4b-c4b61df3799b
        Write-Host "  -"$Event.RunspaceId # 20079932-97f3-424c-aeb3-bf33a3926de2

        Write-Host "  -"$Event.SourceIdentifier # PSTrueCrypt_Creation_Watcher
        Write-Host "  -"$Event.TimeGenerated # 6/21/2017 5:10:15 PM

        Write-Host "  -"$EventArgs.GetHashCode() # 52717909
    
    } -SourceIdentifier "PSTrueCrypt_Creation_Watcher" -MessageData @{ Container=$SubKeyName } -MaxTriggerCount {1} -OperationTimeoutSec 30


    $DeletionFilter = "SELECT * FROM CIM_InstDeletion WITHIN 3 WHERE TargetInstance ISA 'CIM_LogicalDisk'"

    Register-CimIndicationEvent -Query $DeletionFilter -Action { 

        Write-Host "Deletion >>>  <<<"
        Write-Host "  -"$Event.toString() # System.Management.Automation.PSEventArgs
        Write-Host "  -"$Event.EventIdentifier # 1
        Write-Host "  -"$Event.MessageData.Container # 
        Write-Host "  -"$Event.RunspaceId # 20079932-97f3-424c-aeb3-bf33a3926de2

        Write-Host "  -"$Event.SourceIdentifier # PSTrueCrypt_Creation_Watcher
        Write-Host "  -"$Event.TimeGenerated # 6/21/2017 5:10:15 PM

        Write-Host "  -"$EventArgs.GetHashCode() # 52717909
    
    } -SourceIdentifier "PSTrueCrypt_Deletion_Watcher" -MessageData @{ Container=$SubKeyName } -MaxTriggerCount {1} 
}

function Stop-Watch
{
    Unregister-Event -SourceIdentifier "PSTrueCrypt_Creation_Watcher" 
    Unregister-Event -SourceIdentifier "PSTrueCrypt_Deletion_Watcher" 
}