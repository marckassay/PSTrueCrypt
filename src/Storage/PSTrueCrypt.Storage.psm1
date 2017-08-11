using module .\Container.psm1
using module ..\Writer\PSTrueCrypt.Writer.psm1

function Get-RegistrySubKeys
{
    [CmdletBinding()]
    [OutputType([PsObject])]
    Param
    (
        [Parameter(Mandatory = $False)]
        [ScriptBlock]$FilterScript,

        [Parameter(Mandatory = $False)]
        [string]$Path
    )

    end
    {
        try 
        {
            if(-not $Path) {
                $Path = Get-Location
            }

            if($FilterScript) {
                Get-ChildItem $Path -UseTransaction | Where-Object -FilterScript $FilterScript -OutVariable RegistrySubKeys
            } else {
                Get-ChildItem $Path -UseTransaction -OutVariable RegistrySubKeys
            }

            if($RegistrySubKeys.Length -eq 0) {
                throw 'UnableToReadRegistry'
            }
        }
        catch 
        {
            # TODO: Need to throw specific error to calling method
            Out-Error 'UnableToReadRegistry'
        }
        finally
        {

        }
    }
}

function Get-SubKeyNames
{
    [CmdletBinding()]
    [OutputType([String[]])]
    Param
    (
        # TOOD: change to ValueFromPipelineByPropertyName
        [Parameter(Mandatory = $True, Position = 1, ValueFromPipeline=$True)]
        [AllowNull()]
        [PsObject]$RegistrySubKeys,

        [Parameter(Mandatory = $True)]
        [string]$Path
    )

    process
    {
        try 
        {
            if($RegistrySubKeys) {
                $P = Join-Path $Path -Child $RegistrySubKeys.PSChildName
                Get-ItemPropertyValue -Path $P -Name Name -OutVariable +Names -UseTransaction
            }
        }
        catch [System.Security.SecurityException]
        {
            # TODO: Need to throw specific error to calling method
            Out-Error 'UnableToReadRegistry'
        }
        finally
        {

        }
    }
}

function Get-SubKeyByPropertyValue
{
    [CmdletBinding()]
    [OutputType([PsObject])]
    Param
    (
        # TOOD: change to ValueFromPipelineByPropertyName
        [Parameter(Mandatory = $True, ValueFromPipeline=$True)]
        [AllowNull()]
        [PsObject]$RegistrySubKeys,

        [Parameter(Mandatory = $False)]
        [string]$Id,

        [Parameter(Mandatory = $False)]
        [string]$Name,

        [Parameter(Mandatory = $False)]
        [string]$MountLetter
    )

    process
    {
        try 
        {
            if($RegistrySubKeys)
            {
                $Path = Get-Location -UseTransaction
                $P = Join-Path $Path -Child $RegistrySubKeys.PSChildName

                if($Id) {
                    if((Get-ItemPropertyValue -Path $P -Name PSChildName -UseTransaction) -eq $Id) {
                        $FoundKey = $_
                    }
                } elseif($Name) {
                    if((Get-ItemPropertyValue -Path $P -Name Name -UseTransaction) -eq $Name) {
                        $FoundKey = $_
                    }
                } elseif($MountLetter) {
                    if((Get-ItemPropertyValue -Path $P -Name MountLetter -UseTransaction) -eq $MountLetter) {
                        $FoundKey = $_
                    }
                }
            }
        }
        catch [System.Security.SecurityException]
        {
            # TODO: Need to throw specific error to calling method
            Out-Error 'UnableToReadRegistry'
        }
        finally
        {

        }
    }

    end
    {
        $FoundKey
    }
}

function Remove-SubKeyByPropertyValue
{
    [CmdletBinding()]
    [OutputType([void])]
    Param
    (
        # TOOD: change to ValueFromPipelineByPropertyName
        [Parameter(Mandatory = $True, ValueFromPipeline=$True)]
        [AllowNull()]
        [PsObject]$RegistrySubKeys,

        [Parameter(Mandatory = $False)]
        [string]$Id,

        [Parameter(Mandatory = $False)]
        [string]$Name
    )
    
    process
    {
        try 
        {
            if($RegistrySubKeys)
            {
                if($Id) {
                    if((Get-ItemPropertyValue $_.PSChildName -Name PSChildName -UseTransaction) -eq $Id) {
                        Remove-Item $_.PSChildName -UseTransaction -Recurse -Force
                    }
                } elseif($Name) {
                    if((Get-ItemPropertyValue $_.PSChildName -Name Name -UseTransaction) -eq $Name) {
                        Remove-Item $_.PSChildName -UseTransaction -Recurse -Force
                    }
                }
            }
        }
        catch [System.Security.SecurityException]
        {
            # TODO: Need to throw specific error to calling method
            Out-Error 'UnableToReadRegistry'
        }
        finally
        {

        }
    }

    end
    {
       
    }
}

function New-Container
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $True, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]$Location,

        [Parameter(Mandatory = $True, Position = 3)]
        [ValidatePattern("^[a-zA-Z]$")]
        [string]$MountLetter,

        [Parameter(Mandatory = $True, Position = 4)]
        [ValidateSet("TrueCrypt", "VeraCrypt")]
        [string]$Product,

        [switch]$Timestamp
    )

    $Container = [Container]::new()
    $Container.NewSubKey()
    $Container.SetName($Name)
    $Container.SetLocation($Location)
    $Container.SetMountLetter($MountLetter)
    $Container.SetProduct($Product)
    $Container.SetTimestamp($Timestamp.IsPresent)
}

function Write-Container
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $False, ValueFromPipeline = $True)]
        [AllowNull()]
        [PsObject]$RegistrySubKey,

        [Parameter(Mandatory = $False, 
         HelpMessage="Enter the generated Id for this container.")]
        [ValidateNotNullOrEmpty()]
        [string]$KeyId,

        [Parameter(Mandatory = $False)]
        [bool]$IsMounted,

        [Parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()]
        [string]$Location,

        [Parameter(Mandatory = $False)]
        [ValidatePattern("^[a-zA-Z]$")]
        [string]$MountLetter,

        [Parameter(Mandatory = $False)]
        [ValidateSet("TrueCrypt", "VeraCrypt")]
        [string]$Product,

        [Parameter(Mandatory = $False)]
        [ValidatePattern("^[a-zA-Z]$")]
        [string]$LastMountedUri,

        [switch]$NoActivity,

        [switch]$Timestamp,

        [switch]$UseIndependentTransaction
    )

    begin
    {
        if($UseIndependentTransaction.IsPresent) {
            Invoke-BeginBlock -IndependentTransaction:$IndependentTransaction
        }
    }

    process
    {
        if($RegistrySubKey -or $KeyId)
        {
            $Container = [Container]::new()
            if ($KeyId) {
                $Container.SetKeyId($KeyId)
            } else {
                $Container.SetKey($RegistrySubKey)
            }

            if($Name) {
                $Container.SetName($Name)
            }
            
            if($Location) {
                $Container.SetLocation($Location)
            }

            if($MountLetter) {
                $Container.SetMountLetter($MountLetter)
            }
            
            if($Product) {
                $Container.SetProduct($Product)
            }
    
            if($LastMountedUri) {
                $Container.SetLastMountedUri($LastMountedUri)
            }

            $Container.SetIsMounted($IsMounted)

            if($Timestamp.IsPresent) {
                $Container.SetTimestamp($True)
            }

            # if this is switched (True), that means we dont want to record this activity
            if($NoActivity.IsPresent -eq $False) {
                $Container.SetLastActivity( (Get-Date) )
            }
        }
    }

    end
    {
        if($UseIndependentTransaction.IsPresent) {
            Invoke-EndBlock 
        }
    }
}

function Read-Container
{
    [CmdletBinding()]
    [OutputType([HashTable])]
    Param
    (
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [AllowNull()]
        [PsObject]$RegistrySubKey
    )

    process 
    {
        if($RegistrySubKey) 
        {
            $Container = [Container]::new()
            $Container.SetKey($RegistrySubKey)
            $HashTable = $Container.GetHashTable()
            $HashTable
        }
    }

    end
    {
        
    }
}

Export-ModuleMember -Function Get-RegistrySubKeys
Export-ModuleMember -Function Get-SubKeyNames
Export-ModuleMember -Function Get-SubKeyByPropertyValue
Export-ModuleMember -Function Remove-SubKeyByPropertyValue

Export-ModuleMember -Function New-Container
Export-ModuleMember -Function Write-Container
Export-ModuleMember -Function Read-Container