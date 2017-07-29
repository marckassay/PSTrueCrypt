using namespace Microsoft.PowerShell.Commands.Internal
using namespace Microsoft.Win32
using namespace System.Management.Automation
using namespace System.Security.AccessControl

class Container
{
    hidden [bool] $IsNewSubKey = $False

    hidden [TransactedRegistryKey] $SubKey

    [TransactedRegistryKey] GetKey () {
        return $this.SubKey
    }
    [void] SetKey ([TransactedRegistryKey]$Value) {
        $this.SubKey = $Value
    }


    # example of PSChildName: 83adbc84-168f-4f4f-a374-a1b70091f8dd
    [string] GetKeyId () {
        return $this.SubKey.PSChildName
    }
    [void] SetKeyId ([string]$Value) {
        try {
            [System.Guid]::Parse($Value)
        } catch {
            throw "PSTrueCrypt's Container.SetKeyId() received invalid data."
        }

        $this.SubKey = Get-Item $Value
    }


    [string] GetName () {
        return Get-ItemPropertyValue -Path $this.GetKeyId() -Name Name -UseTransaction
    }
    [void] SetName ([string]$Value) {
        if($Value -ne $null) {
            if(-not $this.IsNewSubKey) {
                Set-ItemProperty -Path $this.GetKeyId() -Name Name -Value $Value -PropertyType String -UseTransaction 
            } else {
                New-ItemProperty -Path $this.GetKeyId() -Name Name -Value $Value -PropertyType String -UseTransaction 
            }
        } 
    }


    [string] GetLocation () {
        return Get-ItemPropertyValue -Path $this.GetKeyId() -Name Location -UseTransaction
    }
    [void] SetLocation ([string]$Value) {
        if($Value -ne $null) {
            if(-not $this.IsNewSubKey) {
                Set-ItemProperty -Path $this.GetKeyId() -Name Location -Value $Value -PropertyType String -UseTransaction 
            } else {
                New-ItemProperty -Path $this.GetKeyId() -Name Location -Value $Value -PropertyType String -UseTransaction 
            }
        }
    }


    [string] GetMountLetter () {
        return Get-ItemPropertyValue -Path $this.GetKeyId() -Name MountLetter -UseTransaction
    }
    [void] SetMountLetter ([string]$Value) {
        if($Value -ne $null) {
            if(-not $this.IsNewSubKey) {
                Set-ItemProperty -Path $this.GetKeyId() -Name MountLetter -Value $Value -PropertyType String -UseTransaction 
            } else {
                New-ItemProperty -Path $this.GetKeyId() -Name MountLetter -Value $Value -PropertyType String -UseTransaction 
            }
        }
    }


    [string] GetLastMountedUri () {
        return Get-ItemPropertyValue -Path $this.GetKeyId() -Name LastMountedUri -UseTransaction
    }
    [void] SetLastMountedUri ([string]$Value) {
        if(-not $this.IsNewSubKey) {
            Set-ItemProperty -Path $this.GetKeyId() -Name LastMountedUri -Value $Value -PropertyType String -UseTransaction 
        } else {
            New-ItemProperty -Path $this.GetKeyId() -Name LastMountedUri -Value $Value -PropertyType String -UseTransaction 
        }
    }


    [string] GetProduct () {
        return Get-ItemPropertyValue -Path $this.GetKeyId() -Name Product -UseTransaction
    }
    [void] SetProduct ([string]$Value) {
        if($Value -ne $null) {
            if(-not $this.IsNewSubKey) {
                Set-ItemProperty -Path $this.GetKeyId() -Name Product -Value $Value -PropertyType String -UseTransaction 
            } else {
                New-ItemProperty -Path $this.GetKeyId() -Name Product -Value $Value -PropertyType String -UseTransaction 
            }
        }
    }


    [bool] GetTimestamp () {
        return Get-ItemPropertyValue -Path $this.GetKeyId() -Name Timestamp -UseTransaction
    }
    [void] SetTimestamp ([bool]$Value) {
        if(-not $this.IsNewSubKey) {
            Set-ItemProperty -Path $this.GetKeyId() -Name Timestamp -Value ($Value.GetHashCode()) -PropertyType DWord -UseTransaction 
        } else {
            New-ItemProperty -Path $this.GetKeyId() -Name Timestamp -Value ($Value.GetHashCode()) -PropertyType DWord -UseTransaction 
        }
    }


    [bool] GetIsMounted () {
        return Get-ItemPropertyValue -Path $this.GetKeyId() -Name IsMounted -UseTransaction
    }
    [void] SetIsMounted ([bool]$Value) {
        if(-not $this.IsNewSubKey) {
            Set-ItemProperty -Path $this.GetKeyId() -Name IsMounted -Value ($Value.GetHashCode()) -PropertyType DWord -UseTransaction 
        } else {
            New-ItemProperty -Path $this.GetKeyId() -Name IsMounted -Value ($Value.GetHashCode()) -PropertyType DWord -UseTransaction 
        }
    }


    [string] GetLastActivity () {
        return Get-ItemPropertyValue -Path $this.GetKeyId() -Name LastActivity -UseTransaction
    }
    [void] SetLastActivity ([string]$Value) {
        if($Value -ne $null) {
            if(-not $this.IsNewSubKey) {
                Set-ItemProperty -Path $this.GetKeyId() -Name LastActivity -Value $Value -PropertyType String -UseTransaction 
            } else {
                New-ItemProperty -Path $this.GetKeyId() -Name LastActivity -Value $Value -PropertyType String -UseTransaction 
            }
        }
    }


    [hashtable] GetHashTable() {
        $hash = @{
            KeyId       = $this.GetKeyId()
            KeyPath     = $this.GetKeyId()
            Name        = $this.GetName()
            Location    = $this.GetLocation()
            MountLetter = $this.GetMountLetter()
            Product     = $this.GetProduct()
            Timestamp   = $this.GetTimestamp()
            IsMounted   = $this.GetIsMounted()
            LastActivity  = $this.GetLastActivity()
        }
        return $hash
    }

    [void] NewSubKey () {
        $Id = New-Guid | Select-Object -ExpandProperty Guid

        $this.SubKey = New-Item -Name $Id -UseTransaction

        $this.IsNewSubKey = $True

        $this.SetLastMountedUri("")
        $this.SetIsMounted($False)
        $this.SetLastActivity((Get-Date))
    }
}