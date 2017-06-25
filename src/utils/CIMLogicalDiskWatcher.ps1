using module .\UtilTimer.psm1
function Start-CIMLogicalDiskWatch
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
        # "Restart" the timer while we attempt to mount, we dont want any conflicts with 
        # instances.  This will start immediately but will not raise an event until 
        # the interval has been met
Write-Host "Stop-Timer>>> "
        Stop-Timer
    }

    process
    {
Write-Host "Start-CIMLogicalDiskWatch >>> "
        if($SubKeyName) {
            $ShortName = $SubKeyName.Substring(0,8)
        
            # There may be an issue with this line; if user does a quick double-submit, it may remove the first 
            # event and eventsubscriber but if the first submit gets mounted, then it will prevent the second from
            # ever receiving a creation instance.  at any rate, Restart-CIMLogicalDiskWatch should come by and notice it.
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
    }

    end
    {
Write-Host "Start-Timer>>> "
        Start-Timer
    }
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
Write-Host "Stop-CIMLogicalDiskWatch >>> "

    if($SubKeyName) {
        $ShortName = $SubKeyName.Substring(0,8)
    }
    
    $SourceId = "PSTrueCrypt_"+$InstanceType+"_Watcher_"+$ShortName

    Unregister-Event -SourceIdentifier $SourceId -ErrorAction Ignore
    Remove-Event -SourceIdentifier $SourceId -ErrorAction Ignore
}

function Restart-CIMLogicalDiskWatch
{
    #Get-EventSubscriber -SourceIdentifier CIMLogicalDiskWatch.Timer
    Unregister-Event -SourceIdentifier CIMLogicalDiskWatch.Timer -ErrorAction Ignore
    Register-ObjectEvent -InputObject (New-Timer) -EventName Elapsed -SourceIdentifier 'CIMLogicalDiskWatch.Timer' -Action {
Write-Host ">>>pulse<<<"
        # TODO: we should check for 'Deletion' instances too.  Perhaps add a passthru param 
        # for Start-CIMLogicalDiskWatch and pipe another call to it.
        # Get containers that have a 'mounted' status AND have been mounted more then 3 minutes...  -gt ((Get-Date) - (New-TimeSpan -Minutes 3))
       PSTrueCrypt\Get-MountedContainers -FilterScript { ($_.GetValue('IsMounted') -eq $True) -AND (Get-Date $_.GetValue('LastActivity')) -lt ((Get-Date) - (New-TimeSpan -Minutes 3)) } | Start-CIMLogicalDiskWatch -InstanceType 'Creation'
    }

    Start-Timer
}