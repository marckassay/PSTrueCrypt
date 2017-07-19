using namespace Microsoft.Win32
using namespace System.Management.Automation
using namespace Microsoft.PowerShell.Commands.Internal

class Container
{
    static [Container] $instance

    static [Container] GetInstance()
    {
        if ([Container]::instance -eq $null) {
            [Container]::instance = [Container]::new()
        }

        return [Container]::instance
    }



    hidden [TransactedRegistryKey] $SubKey

    hidden [string] $KeyName

    [string] GetKeyName () {
        return $this.SubKey.PSChildName
    }

    hidden [string] $KeyPath

    [string] GetKeyPath () {
        if ($this.KeyPath -eq $null) {
            if($this.SubKey -ne $null) {
                $this.KeyPath = $this.SubKey.PSPath
            } else { 
                $Path = Get-Location | Select-Object -ExpandProperty Path
                $Name = New-Guid | Select-Object -ExpandProperty Guid
                $this.KeyPath = "$Path\$Name"
            }
        }

        return $this.KeyPath
    }

    # immutable property
    hidden [bool]$_ReadOnly = $False
    hidden [bool]$_ReadOnlyHasBeenMutated = $False
    hidden [bool] ReadOnly ([bool]$Value) {
        if($Value -eq $True) {
            if($this._ReadOnlyHasBeenMutated -eq $False) {
                $this._ReadOnlyHasBeenMutated = $True
                $this._ReadOnly = $True
            }
        }

        return $this._ReadOnly
    }

    # its important to be aware of how PowerShell handles Transactions.  if this
    # class is created more then once while the first is still "active", it can only
    # work on the latest transaction.  Once the latest/last transaction is completed,
    # it will work on the previous transaction.
    hidden [void] RequestTransaction () {
        if(Get-Transaction -ne Active) {
            Start-Transaction
        }
    }

   [void] SetName ([string]$Value) {
        if($Value -ne $null) {
            RequestTransaction

            if($this.GetKeyPath()) {
                Set-ItemProperty -Path $this.GetKeyPath() -Name Name -Value $Value -PropertyType String -UseTransaction 
            } else {
                New-ItemProperty -Path $this.GetKeyPath() -Name Name -Value $Value -PropertyType String -UseTransaction 
            }
        } 
    }

    [string] GetName () {
        return Get-ItemPropertyValue -Path $this.KeyPath -Name Name -UseTransaction
    }

   [void] SetLocation ([string]$Value) {
        if($Value -ne $null) {
            RequestTransaction

            if($this.GetKeyPath()) {
                Set-ItemProperty -Path $this.GetKeyPath() -Name Location -Value $Value -PropertyType String -UseTransaction 
            } else {
                New-ItemProperty -Path $this.GetKeyPath() -Name Location -Value $Value -PropertyType String -UseTransaction 
            }
        }
    }
    
    [string] GetLocation () {
        return Get-ItemPropertyValue -Path $this.KeyPath -Name Location -UseTransaction
    }

   [void] SetMountLetter ([string]$Value) {
        if($Value -ne $null) {
            RequestTransaction

            if($this.GetKeyPath()) {
                Set-ItemProperty -Path $this.GetKeyPath() -Name MountLetter -Value $Value -PropertyType String -UseTransaction 
            } else {
                New-ItemProperty -Path $this.GetKeyPath() -Name MountLetter -Value $Value -PropertyType String -UseTransaction 
            }
        }
    }
    
    [string] GetMountLetter () {
        return Get-ItemPropertyValue -Path $this.KeyPath -Name MountLetter -UseTransaction
    }

   [void] SetLastMountedUri ([string]$Value) {
        if($Value -ne $null) {
            RequestTransaction

            if($this.GetKeyPath()) {
                Set-ItemProperty -Path $this.GetKeyPath() -Name LastMountedUri -Value $Value -PropertyType String -UseTransaction 
            } else {
                New-ItemProperty -Path $this.GetKeyPath() -Name LastMountedUri -Value $Value -PropertyType String -UseTransaction 
            }
        }
    }

   [string] GetLastMountedUri () {
        return Get-ItemPropertyValue -Path $this.KeyPath -Name LastMountedUri -UseTransaction
    }

   [void] SetProduct ([string]$Value) {
        if($Value -ne $null) {
            RequestTransaction

            if($this.GetKeyPath()) {
                Set-ItemProperty -Path $this.GetKeyPath() -Name Product -Value $Value -PropertyType String -UseTransaction 
            } else {
                New-ItemProperty -Path $this.GetKeyPath() -Name Product -Value $Value -PropertyType String -UseTransaction 
            }
        }
    }

    [string] GetProduct () {
        return Get-ItemPropertyValue -Path $this.KeyPath -Name Product -UseTransaction
    }

   [void] SetTimestamp ([bool]$Value) {
        if($Value -eq $True) {
            RequestTransaction

            if($this.GetKeyPath()) {
                Set-ItemProperty -Path $this.GetKeyPath() -Name Timestamp -Value $Value.GetHashCode() -PropertyType DWord -UseTransaction 
            } else {
                New-ItemProperty -Path $this.GetKeyPath() -Name Timestamp -Value $False.GetHashCode() -PropertyType DWord -UseTransaction 
            }
        }
    }

   [bool] GetTimestamp () {
        return Get-ItemPropertyValue -Path $this.KeyPath -Name Timestamp -UseTransaction
   }

   [void] SetIsMounted ([bool]$Value) {
        if($Value -eq $True) {
            RequestTransaction

            if($this.GetKeyPath()) {
                Set-ItemProperty -Path $this.GetKeyPath() -Name IsMounted -Value $Value.GetHashCode() -PropertyType DWord -UseTransaction 
            } else {
                New-ItemProperty -Path $this.GetKeyPath() -Name IsMounted -Value $False.GetHashCode() -PropertyType DWord -UseTransaction 
            }
        }
    }

   [bool] GetIsMounted () {
        return Get-ItemPropertyValue -Path $this.KeyPath -Name IsMounted -UseTransaction
   }

   [void] SetLastActivity ([string]$Value) {
        if($Value -ne $null) {
            RequestTransaction

            if($this.GetKeyPath()) {
                Set-ItemProperty -Path $this.GetKeyPath() -Name LastActivity -Value $Value -PropertyType String -UseTransaction 
            } else {
                New-ItemProperty -Path $this.GetKeyPath() -Name LastActivity -Value $Value -PropertyType String -UseTransaction 
            }
        }
    }

    [string] GetLastActivity () {
        return Get-ItemPropertyValue -Path $this.KeyPath -Name LastActivity -UseTransaction
    }

    [hashtable] GetHashTable() {
        $hash = @{
            Id          = $this.GetKeyName()
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
    
    [void] Complete () {
        Complete-Transaction
    }

    [void] Undo () {
        Undo-Transaction
    }

    [void] Delete () {
        Remove-Item $this.KeyPath -Recurse
    }
}