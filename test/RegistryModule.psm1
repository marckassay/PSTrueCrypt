function New-SubKey
{
    param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$SubKeyName,
        [Parameter(Mandatory = $True, Position = 2)]
        [string]$Name,
        [Parameter(Mandatory = $True, Position = 3)]
        [string]$Location,
        [Parameter(Mandatory = $True, Position = 4)]
        [string]$MountLetter,
        [Parameter(Mandatory = $True, Position = 5)]
        [string]$Product,
        [Parameter(Mandatory = $True, Position = 6)]
        [string]$LastMountedUri,
        [Parameter(Mandatory = $False)]
        [switch]$Timestamp,
        [Parameter(Mandatory = $False)]
        [switch]$IsMounted
    )
    
    $SubKeyPath = "HKCU:\Software\PSTrueCrypt\Test\00000000-0000-0000-0000-$SubKeyName"

    New-Item -Path $SubKeyPath -Force -UseTransaction
    New-ItemProperty -Path $SubKeyPath -Name Name        -PropertyType String -Value $Name -UseTransaction
    New-ItemProperty -Path $SubKeyPath -Name Location    -PropertyType String -Value $Location -UseTransaction
    New-ItemProperty -Path $SubKeyPath -Name MountLetter -PropertyType String -Value $MountLetter -UseTransaction
    New-ItemProperty -Path $SubKeyPath -Name Product     -PropertyType String -Value $Product -UseTransaction
    New-ItemProperty -Path $SubKeyPath -Name LastMountedUri -PropertyType String -Value $LastMountedUri -UseTransaction
    New-ItemProperty -Path $SubKeyPath -Name Timestamp   -PropertyType DWord -Value $Timestamp.GetHashCode() -UseTransaction
    New-ItemProperty -Path $SubKeyPath -Name IsMounted   -PropertyType DWord -Value $IsMounted.GetHashCode() -UseTransaction
}