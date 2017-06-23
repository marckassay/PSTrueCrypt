function Start-CIMLogicalDiskWatch
{
    Param
    (
        [Parameter(Mandatory = $True, Position = 1, ValueFromPipelineByPropertyName=$True)]
        [ValidateNotNullOrEmpty()]
        [Alias("PSChildName")]
        [String]$SubKeyName,

        [ValidateSet("Creation","Deletion")]
        [Parameter(Mandatory = $True, Position = 2)]
        [String]$InstanceType
    )
    
    if($SubKeyName) {
        $ShortName = $SubKeyName.Substring(0,8)
    }
    
    Stop-CIMLogicalDiskWatch $ShortName $InstanceType

    $SourceId = "PSTrueCrypt_"+$InstanceType+"_Watcher_"+$ShortName

    $Filter = "SELECT * FROM CIM_Inst"+$InstanceType+" WITHIN 1 WHERE TargetInstance ISA 'CIM_LogicalDisk'"

    $void = Register-CimIndicationEvent -Query $Filter -Action { 
        $KeyId = $Event.MessageData.KeyId # f9910b39-dc58-4a34-be4b-c4b61df3799b
        $IsMounted = $Event.SourceIdentifier.Contains('Creation') # PSTrueCrypt_Creation_Watcher_f9910b39
        $LastActivity = $Event.TimeGenerated # 6/21/2017 5:10:15 PM

        Set-PSTrueCryptContainer -SubKeyName $KeyId -IsMounted $IsMounted -LastActivity $LastActivity
    
    } -SourceIdentifier $SourceId -MessageData @{ KeyId=$SubKeyName } -MaxTriggerCount 1 -OperationTimeoutSec 35
}

function Stop-CIMLogicalDiskWatch
{
    Param
    (
        [Parameter(Mandatory = $False, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$SubKeyName,

        [Parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()]
        [string]$ShortName,

        [ValidateSet("Creation","Deletion")]
        [Parameter(Mandatory = $True, Position = 2)]
        [String]$InstanceType
    )

    if($SubKeyName) {
        $ShortName = $SubKeyName.Substring(0,8)
    }

    $SourceId = "PSTrueCrypt_"+$InstanceType+"_Watcher_"+$ShortName

    Unregister-Event -SourceIdentifier $SourceId -ErrorAction Ignore
    Remove-Event -SourceIdentifier $SourceId -ErrorAction Ignore
}

function Restart-CIMLogicalDiskWatch
{
    Param
    (
        [Parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()]
        [string]$SubKeyName
    )
    # Get containers that have a 'mounted' status AND which have been mounted more then 3 minutes...
    Get-MountedContainers -FilterScript { ($_.GetValue('IsMounted') -eq $True) -AND ((Get-Date $_.GetValue('LastActivity')).AddMinutes(3) -lt (Get-Date)) } | Start-CIMLogicalDiskWatch -InstanceType 'Creation'
}