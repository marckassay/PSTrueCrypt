using namespace Microsoft.Win32
using namespace System.Management.Automation
using namespace Microsoft.PowerShell.Commands.Internal

class Container
{
    hidden [TransactedRegistryKey] $SubKey

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
            if($this.GetKeyPath()) {
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
            if($this.GetKeyPath()) {
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
            if($this.GetKeyPath()) {
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
        if($Value -ne $null) {
            if($this.GetKeyPath()) {
                Set-ItemProperty -Path $this.GetKeyPath() -Name LastMountedUri -Value $Value -PropertyType String -UseTransaction 
            } else {
                New-ItemProperty -Path $this.GetKeyPath() -Name LastMountedUri -Value $Value -PropertyType String -UseTransaction 
            }
        }
    }

    [string] GetLastMountedUri () {
        return Get-ItemPropertyValue -Path $this.GetKeyPath() -Name LastMountedUri -UseTransaction
    }

    [void] SetProduct ([string]$Value) {
        if($Value -ne $null) {
            if($this.GetKeyPath()) {
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
        if($Value -eq $True) {
            if($this.GetKeyPath()) {
                Set-ItemProperty -Path $this.GetKeyPath() -Name Timestamp -Value ($Value.GetHashCode()) -PropertyType DWord -UseTransaction 
            } else {
                New-ItemProperty -Path $this.GetKeyPath() -Name Timestamp -Value ($False.GetHashCode()) -PropertyType DWord -UseTransaction 
            }
        }
    }

   [bool] GetTimestamp () {
        return Get-ItemPropertyValue -Path $this.GetKeyPath() -Name Timestamp -UseTransaction
   }

    [void] SetIsMounted ([bool]$Value) {
        if($Value -eq $True) {
            if($this.GetKeyPath()) {
                Set-ItemProperty -Path $this.GetKeyPath() -Name IsMounted -Value ($Value.GetHashCode()) -PropertyType DWord -UseTransaction 
            } else {
                New-ItemProperty -Path $this.GetKeyPath() -Name IsMounted -Value ($False.GetHashCode()) -PropertyType DWord -UseTransaction 
            }
        }
    }

    [bool] GetIsMounted () {
        return Get-ItemPropertyValue -Path $this.GetKeyPath() -Name IsMounted -UseTransaction
    }

    [void] SetLastActivity ([string]$Value) {
        if($Value -ne $null) {
            if($this.GetKeyPath()) {
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

    [void] OpenTrueCryptKey () {
        $AccessRule = New-Object System.Security.AccessControl.RegistryAccessRule (
            [System.Security.Principal.WindowsIdentity]::GetCurrent().Name, "FullControl",
            [System.Security.AccessControl.InheritanceFlags]"ObjectInherit,ContainerInherit",
            [System.Security.AccessControl.PropagationFlags]"None",
            [System.Security.AccessControl.AccessControlType]"Allow")

        $GetRootDirectory = (Get-Location).Drive.CurrentLocation

        [Microsoft.Win32.RegistryKey]$Key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey(($GetRootDirectory+'\'+$this.GetKeyId()),
            [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree)
        
        if(-not $Key) {
            $Id = New-Guid | Select-Object -ExpandProperty Guid

            [Microsoft.Win32.RegistryKey]$Key = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey(($GetRootDirectory+'\'+$Id),
                [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree)

            $this.SubKey = $Key
        }

        $AccessControl = $Key.GetAccessControl()
        $AccessControl.SetAccessRule($AccessRule)
        
        $Key.SetAccessControl($AccessControl)
    }

    [void] Delete () {
        Remove-Item $this.GetKeyPath() -Recurse
    }
}