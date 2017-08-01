using namespace Microsoft.PowerShell.Commands.Internal
using namespace Microsoft.Win32
using namespace System.Management.Automation
using namespace System.Security.AccessControl

class Container
{
    hidden [bool] $IsNewSubKey = $False

    hidden [RegistryKey] $SubKey

    [RegistryKey] GetKey () {
        return $this.SubKey
    }
    [void] SetKey ([RegistryKey]$Value) {
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
        return Get-ItemPropertyValue -Path $this.GetKeyId() -Name Name 
    }
    [void] SetName ([string]$Value) {
        if($Value -ne $null) {
            if(-not $this.IsNewSubKey) {
                Set-ItemProperty -Path $this.GetKeyId() -Name Name -Value $Value  
            } else {
                New-ItemProperty -Path $this.GetKeyId() -Name Name -Value $Value -PropertyType String  
            }
        } 
    }


    [string] GetLocation () {
        return Get-ItemPropertyValue -Path $this.GetKeyId() -Name Location 
    }
    [void] SetLocation ([string]$Value) {
        if($Value -ne $null) {
            if(-not $this.IsNewSubKey) {
                Set-ItemProperty -Path $this.GetKeyId() -Name Location -Value $Value  
            } else {
                New-ItemProperty -Path $this.GetKeyId() -Name Location -Value $Value -PropertyType String  
            }
        }
    }


    [string] GetMountLetter () {
        return Get-ItemPropertyValue -Path $this.GetKeyId() -Name MountLetter 
    }
    [void] SetMountLetter ([string]$Value) {
        if($Value -ne $null) {
            if(-not $this.IsNewSubKey) {
                Set-ItemProperty -Path $this.GetKeyId() -Name MountLetter -Value $Value  
            } else {
                New-ItemProperty -Path $this.GetKeyId() -Name MountLetter -Value $Value -PropertyType String  
            }
        }
    }


    [string] GetLastMountedUri () {
        return Get-ItemPropertyValue -Path $this.GetKeyId() -Name LastMountedUri 
    }
    [void] SetLastMountedUri ([string]$Value) {
        if(-not $this.IsNewSubKey) {
            Set-ItemProperty -Path $this.GetKeyId() -Name LastMountedUri -Value $Value  
        } else {
            New-ItemProperty -Path $this.GetKeyId() -Name LastMountedUri -Value $Value -PropertyType String  
        }
    }


    [string] GetProduct () {
        return Get-ItemPropertyValue -Path $this.GetKeyId() -Name Product 
    }
    [void] SetProduct ([string]$Value) {
        if($Value -ne $null) {
            if(-not $this.IsNewSubKey) {
                Set-ItemProperty -Path $this.GetKeyId() -Name Product -Value $Value  
            } else {
                New-ItemProperty -Path $this.GetKeyId() -Name Product -Value $Value -PropertyType String  
            }
        }
    }


    [bool] GetTimestamp () {
        return Get-ItemPropertyValue -Path $this.GetKeyId() -Name Timestamp 
    }
    [void] SetTimestamp ([bool]$Value) {
        if(-not $this.IsNewSubKey) {
            Set-ItemProperty -Path $this.GetKeyId() -Name Timestamp -Value ($Value.GetHashCode())  
        } else {
            New-ItemProperty -Path $this.GetKeyId() -Name Timestamp -Value ($Value.GetHashCode()) -PropertyType DWord  
        }
    }


    [bool] GetIsMounted () {
        return Get-ItemPropertyValue -Path $this.GetKeyId() -Name IsMounted 
    }
    [void] SetIsMounted ([bool]$Value) {
        if(-not $this.IsNewSubKey) {
            Set-ItemProperty -Path $this.GetKeyId() -Name IsMounted -Value ($Value.GetHashCode())  
        } else {
            New-ItemProperty -Path $this.GetKeyId() -Name IsMounted -Value ($Value.GetHashCode()) -PropertyType DWord  
        }
    }


    [string] GetLastActivity () {
        return Get-ItemPropertyValue -Path $this.GetKeyId() -Name LastActivity 
    }
    [void] SetLastActivity ([string]$Value) {
        if($Value -ne $null) {
            if(-not $this.IsNewSubKey) {
                Set-ItemProperty -Path $this.GetKeyId() -Name LastActivity -Value $Value  
            } else {
                New-ItemProperty -Path $this.GetKeyId() -Name LastActivity -Value $Value -PropertyType String  
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

        $this.SubKey = New-Item -Name $Id 

        $this.IsNewSubKey = $True

        $this.SetLastMountedUri("")
        $this.SetIsMounted($True)
        $this.SetLastActivity((Get-Date))
    }
}