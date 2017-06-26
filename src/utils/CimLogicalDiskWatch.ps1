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
            $ShortName = $SubKeyName.Substring(0,8)
        
            Stop-CIMLogicalDiskWatch $ShortName $InstanceType

            $SourceId = "PSTrueCrypt_"+$InstanceType+"_Watcher_"+$ShortName

            $Filter = "SELECT * FROM CIM_Inst"+$InstanceType+" WITHIN 1 WHERE TargetInstance ISA 'CIM_LogicalDisk'"

            $void = Register-CimIndicationEvent -Query $Filter -Action { 
                $KeyId = $Event.MessageData.KeyId # f9910b39-dc58-4a34-be4b-c4b61df3799b
                $IsMounted = $Event.SourceIdentifier.Contains('Creation') # PSTrueCrypt_Creation_Watcher_f9910b39
                $LastActivity = $Event.TimeGenerated # 6/21/2017 5:10:15 PM

                $e=$Event
                $d=$EventSubscriber
                $c=$Sender
                $b=$SourceEventArgs
                $a=$SourceArgs 

                Set-PSTrueCryptContainer -SubKeyName $KeyId -IsMounted $IsMounted -LastActivity $LastActivity
            
            } -SourceIdentifier $SourceId -MessageData @{ KeyId=$SubKeyName } -MaxTriggerCount 1 -OperationTimeoutSec 35
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