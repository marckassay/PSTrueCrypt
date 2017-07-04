using namespace Microsoft.Win32
using namespace System.Management.Automation

class Container
{
    hidden [RegistryKey] $SubKey

    Container ([RegistryKey]$SubKey) {
        $this.SubKey = $SubKey
    }
 
    hidden [PSTransaction] $RequestTransaction {
        if(Get-Transaction -eq Active) {
            return Get-Transaction
        } else {
            return Start-Transaction
        }
    }
    
    hidden [string] $_SubKeyPath
    hidden [string] $SubKeyPath {
        if { $_SubKeyPath -eq $null} {
            if($SubKey -ne $null) {
                $_SubKeyPath = $SubKey.PSChildPath
            } else { 
                $_SubKeyPath = New-Guid
            }
        }

        return $_SubKeyPath
    }

   [string] $Name ([string]$Value=$null) {
        if($Value) {
            $RequestTransaction

            if($SubKeyPath) {
                Set-ItemProperty -Path $SubKeyPath -Name Name -Value $Value -PropertyType String -UseTransaction 
            } else {
                New-ItemProperty -Path $SubKeyPath -Name Name -Value $Value -PropertyType String -UseTransaction 
            }
        } else {
            Get-ItemPropertyValue -Path $SubKeyPath -Name Name
        }
    }

   [string] $Location ([string]$Value=$null) {
        if($Value) {
            $RequestTransaction

            if($SubKeyPath) {
                Set-ItemProperty -Path $SubKeyPath -Name Location -Value $Value -PropertyType String -UseTransaction 
            } else {
                New-ItemProperty -Path $SubKeyPath -Name Location -Value $Value -PropertyType String -UseTransaction 
            }
        } else {
            Get-ItemPropertyValue -Path $SubKeyPath -Name Location
        }
    }

   [string] $MountLetter ([string]$Value=$null) {
        if($Value) {
            $RequestTransaction

            if($SubKeyPath) {
                Set-ItemProperty -Path $SubKeyPath -Name MountLetter -Value $Value -PropertyType String -UseTransaction 
            } else {
                New-ItemProperty -Path $SubKeyPath -Name MountLetter -Value $Value -PropertyType String -UseTransaction 
            }
        } else {
            Get-ItemPropertyValue -Path $SubKeyPath -Name MountLetter
        }
    }

   [string] $Product ([string]$Value=$null) {
        if($Value) {
            $RequestTransaction

            if($SubKeyPath) {
                Set-ItemProperty -Path $SubKeyPath -Name Product -Value $Value -PropertyType String -UseTransaction 
            } else {
                New-ItemProperty -Path $SubKeyPath -Name Product -Value $Value -PropertyType String -UseTransaction 
            }
        } else {
            Get-ItemPropertyValue -Path $SubKeyPath -Name Product
        }
    }

   [bool] $Timestamp ([bool]$Value=$null) {
        if($Value) {
            $RequestTransaction

            if($SubKeyPath) {
                Set-ItemProperty -Path $SubKeyPath -Name Timestamp -Value $Value.GetHashCode() -PropertyType DWord -UseTransaction 
            } else {
                New-ItemProperty -Path $SubKeyPath -Name Timestamp -Value $False.GetHashCode() -PropertyType DWord -UseTransaction 
            }
        } else {
            [bool](Get-ItemPropertyValue -Path $SubKeyPath -Name Timestamp)
        }
    }

   [bool] $IsMounted ([bool]$Value=$null) {
        if($Value) {
            $RequestTransaction

            if($SubKeyPath) {
                Set-ItemProperty -Path $SubKeyPath -Name IsMounted -Value $Value.GetHashCode() -PropertyType DWord -UseTransaction 
            } else {
                New-ItemProperty -Path $SubKeyPath -Name IsMounted -Value $False.GetHashCode() -PropertyType DWord -UseTransaction 
            }
        } else {
            [bool](Get-ItemPropertyValue -Path $SubKeyPath -Name IsMounted)
        }
    }

   [string] $LastActivity ([string]$Value=$null) {
        if($Value) {
            $RequestTransaction

            if($SubKeyPath) {
                Set-ItemProperty -Path $SubKeyPath -Name LastActivity -Value $Value -PropertyType String -UseTransaction 
            } else {
                New-ItemProperty -Path $SubKeyPath -Name LastActivity -Value $Value -PropertyType String -UseTransaction 
            }
        } else {
            Get-ItemPropertyValue -Path $SubKeyPath -Name LastActivity
        }
    }
    
    [void] $Save {
        Complete-Transaction
    }

    [void] $Delete {
        Remove-Item $SubKeyPath -Recurse
    }
}