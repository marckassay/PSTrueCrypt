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
        
            Stop-CimLogicalDiskWatch $ShortName $InstanceType

            $SourceId = "PSTrueCrypt_"+$InstanceType+"_Watcher_"+$ShortName

            $Filter = "SELECT * FROM CIM_Inst"+$InstanceType+" WITHIN 1 WHERE TargetInstance ISA 'CIM_LogicalDisk'"

            # TODO: temp hack until I can retrieve DeviceID inside the Action block for Register-CimIndicationEvent.  this
            # problematic if the mounting executing changes uri from MountedLetter.  For instance if MountedLetter is already
            # in use and it changes uri.
            $PredeterminedDeviceID = (Get-PSTrueCryptContainers -FilterScript {$_.PSChildName -eq $SubKeyName} | Get-ItemProperty -Name MountLetter).MountLetter

            $void = Register-CimIndicationEvent -Query $Filter -Action { 
                $KeyId = $Event.MessageData.KeyId # f9910b39-dc58-4a34-be4b-c4b61df3799b
                $DeviceID = $Event.MessageData.LastMountedUri
                $IsMounted = $Event.SourceIdentifier.Contains('Creation') # PSTrueCrypt_Creation_Watcher_f9910b39
                $LastActivity = $Event.TimeGenerated # 6/21/2017 5:10:15 PM
                #TODO:  I no longer seem to be able to have the debugger break in this block.
                # I would like to get the DeviceID (Get-CimInstance -ClassName CIM_LogicalDisk) from this instance
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
                Set-PSTrueCryptContainer -SubKeyName $KeyId -IsMounted $IsMounted -LastActivity $LastActivity -LastMountedUri $DeviceID
            } -SourceIdentifier $SourceId -MessageData @{ KeyId=$SubKeyName; LastMountedUri=$PredeterminedDeviceID } -MaxTriggerCount 1 -OperationTimeoutSec 35
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