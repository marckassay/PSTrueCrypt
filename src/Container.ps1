using namespace Microsoft.Win32

class Container
{
    [RegistryKey] $SubKey

    Container ([RegistryKey]$SubKey)
    {
        $this.SubKey = $SubKey
    }

    [String]Name
    [String]GetName() {

    }
    [void]SetName([String]value){

    }

    <#
    Name        -PropertyType String -Value $Name)
    Location    -PropertyType String -Value $Location)
    MountLetter -PropertyType String -Value $MountLetter)
    Product     -PropertyType String -Value $Product)
    Timestamp   -PropertyType DWord -Value $Timestamp.GetHashCode())
    IsMounted   -PropertyType DWord -Value $False.GetHashCode())
    LastActivity -PropertyType String -Value $CreationDate)
    >#
}


