using namespace Microsoft.PowerShell.Commands.Internal
using namespace Microsoft.Win32
using namespace System.Management.Automation
using namespace System.Security.AccessControl

class Container
{
    hidden [TransactedRegistryKey] $SubKey

    hidden [bool] $IsNewSubKey = $False

    [TransactedRegistryKey] GetKey () {
        return $this.SubKey
    }
    [void] SetKey ([TransactedRegistryKey]$Value) {
        $this.SubKey = $Value
    }

    # example of PSPath: Microsoft.PowerShell.Core\Registry::HKEY_CURRENT_USER\Software\PSTrueCrypt\83adbc84-168f-4f4f-a374-a1b70091f8dd\
    [string] GetKeyPath () {
        return $this.SubKey.PSChildName
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

    [void] SetName ([string]$Value) {
        if($Value -ne $null) {
            if(-not $this.IsNewSubKey) {
                Set-ItemProperty -Path $this.GetKeyPath() -Name Name -Value $Value -PropertyType String -UseTransaction 
            } else {
                New-ItemProperty -Path $this.GetKeyPath() -Name Name -Value $Value -PropertyType String -UseTransaction 
            }
        } 
    }

    [string] GetName () {
        return Get-ItemPropertyValue -Path $this.GetKeyPath() -Name Name -UseTransaction
    }

    [void] SetLocation ([string]$Value) {
        if($Value -ne $null) {
            if(-not $this.IsNewSubKey) {
                Set-ItemProperty -Path $this.GetKeyPath() -Name Location -Value $Value -PropertyType String -UseTransaction 
            } else {
                New-ItemProperty -Path $this.GetKeyPath() -Name Location -Value $Value -PropertyType String -UseTransaction 
            }
        }
    }
    
    [string] GetLocation () {
        return Get-ItemPropertyValue -Path $this.GetKeyPath() -Name Location -UseTransaction
    }

    [void] SetMountLetter ([string]$Value) {
        if($Value -ne $null) {
            if(-not $this.IsNewSubKey) {
                Set-ItemProperty -Path $this.GetKeyPath() -Name MountLetter -Value $Value -PropertyType String -UseTransaction 
            } else {
                New-ItemProperty -Path $this.GetKeyPath() -Name MountLetter -Value $Value -PropertyType String -UseTransaction 
            }
        }
    }
    
    [string] GetMountLetter () {
        return Get-ItemPropertyValue -Path $this.GetKeyPath() -Name MountLetter -UseTransaction
    }

    [void] SetLastMountedUri ([string]$Value) {
        if(-not $this.IsNewSubKey) {
            Set-ItemProperty -Path $this.GetKeyPath() -Name LastMountedUri -Value $Value -PropertyType String -UseTransaction 
        } else {
            New-ItemProperty -Path $this.GetKeyPath() -Name LastMountedUri -Value $Value -PropertyType String -UseTransaction 
        }
    }

    [string] GetLastMountedUri () {
        return Get-ItemPropertyValue -Path $this.GetKeyPath() -Name LastMountedUri -UseTransaction
    }

    [void] SetProduct ([string]$Value) {
        if($Value -ne $null) {
            if(-not $this.IsNewSubKey) {
                Set-ItemProperty -Path $this.GetKeyPath() -Name Product -Value $Value -PropertyType String -UseTransaction 
            } else {
                New-ItemProperty -Path $this.GetKeyPath() -Name Product -Value $Value -PropertyType String -UseTransaction 
            }
        }
    }

    [string] GetProduct () {
        return Get-ItemPropertyValue -Path $this.GetKeyPath() -Name Product -UseTransaction
    }

    [void] SetTimestamp ([bool]$Value) {
        if(-not $this.IsNewSubKey) {
            Set-ItemProperty -Path $this.GetKeyPath() -Name Timestamp -Value ($Value.GetHashCode()) -PropertyType DWord -UseTransaction 
        } else {
            New-ItemProperty -Path $this.GetKeyPath() -Name Timestamp -Value ($Value.GetHashCode()) -PropertyType DWord -UseTransaction 
        }
    }

   [bool] GetTimestamp () {
        return Get-ItemPropertyValue -Path $this.GetKeyPath() -Name Timestamp -UseTransaction
   }

    [void] SetIsMounted ([bool]$Value) {
        if(-not $this.IsNewSubKey) {
            Set-ItemProperty -Path $this.GetKeyPath() -Name IsMounted -Value ($Value.GetHashCode()) -PropertyType DWord -UseTransaction 
        } else {
            New-ItemProperty -Path $this.GetKeyPath() -Name IsMounted -Value ($False.GetHashCode()) -PropertyType DWord -UseTransaction 
        }
    }

    [bool] GetIsMounted () {
        return Get-ItemPropertyValue -Path $this.GetKeyPath() -Name IsMounted -UseTransaction
    }

    [void] SetLastActivity ([string]$Value) {
        if($Value -ne $null) {
            if(-not $this.IsNewSubKey) {
                Set-ItemProperty -Path $this.GetKeyPath() -Name LastActivity -Value $Value -PropertyType String -UseTransaction 
            } else {
                New-ItemProperty -Path $this.GetKeyPath() -Name LastActivity -Value $Value -PropertyType String -UseTransaction 
            }
        }
    }

    [string] GetLastActivity () {
        return Get-ItemPropertyValue -Path $this.GetKeyPath() -Name LastActivity -UseTransaction
    }

    [hashtable] GetHashTable() {
        $hash = @{
            KeyId       = $this.GetKeyId()
            KeyPath     = $this.GetKeyPath()
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

    [void] OpenSubKey () {
        $PSTrueCryptKey = (Get-Location).Drive.CurrentLocation

        [RegistryKey]$Key = [RegistryKey]::CurrentUser.OpenSubKey(($PSTrueCryptKey+'\'+$this.GetKeyId()), [RegistryKeyPermissionCheck]::ReadWriteSubTree)


        $AccessRule = New-Object System.Security.AccessControl.RegistryAccessRule (
        [System.Security.Principal.WindowsIdentity]::GetCurrent().Name, "FullControl",
        [InheritanceFlags]"ObjectInherit,ContainerInherit",
        [PropagationFlags]"None",
        [AccessControlType]"Allow")

        $AccessControl = $Key.GetAccessControl()
        $AccessControl.SetAccessRule($AccessRule)
        
        $Key.SetAccessControl($AccessControl)
    }

    [void] NewSubKey () {
        $Id = New-Guid | Select-Object -ExpandProperty Guid

        $this.SubKey = New-Item -Name $Id -UseTransaction

        $this.IsNewSubKey = $True

        $this.SetLastMountedUri("")
        $this.SetLastActivity((Get-Date))
    }
}