using module .\Container.psm1

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

    process
    {
        try 
        {
            if(-not $Path) {
                $Path = Get-Location
            }

            if($FilterScript) {
                Get-ChildItem -Path $Path -Recurse -UseTransaction | Where-Object -FilterScript $FilterScript -OutVariable $RegistrySubKeys
            } else {
                Get-ChildItem -Path $Path -Recurse -OutVariable $RegistrySubKeys -UseTransaction
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
        $RegistrySubKeys
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
        [PsObject]$RegistrySubKeys
    )

    process
    {
        try 
        {
            if($RegistrySubKeys) {
                $RegistrySubKeys | Get-ItemPropertyValue -Name Name -PipelineVariable $Names
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
                if($Id) {
                    if(($RegistrySubKeys | Get-ItemPropertyValue -Name PSChildName -UseTransaction) -eq $Id) {
                        $FoundKey = $_
                    }
                } elseif($Name) {
                    if(($RegistrySubKeys | Get-ItemPropertyValue -Name Name -UseTransaction) -eq $Name) {
                        $FoundKey = $_
                    }
                } elseif($MountLetter) {
                    if(($RegistrySubKeys | Get-ItemPropertyValue -Name MountLetter -UseTransaction) -eq $MountLetter) {
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
            if($Id) {
                $RegistrySubKeys | Get-SubKeyByPropertyValue -Name $Id | Remove-Item -Path $_.PSPath -Recurse
            } elseif($Name) {
                $RegistrySubKeys | Get-SubKeyByPropertyValue -Name $Name | Remove-Item -Path $_.PSPath -Recurse
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

        [switch]$IsMounted,

        [switch]$Timestamp
    )

    $Container = [Container]::new()
    $Container.OpenTrueCryptKey()
    $Container.SetName($Name)
    $Container.SetLocation($Location)
    $Container.SetMountLetter($MountLetter)
    $Container.SetProduct($Product)
    $Container.SetIsMounted($IsMounted)
    $Container.SetTimestamp($Timestamp)
    $Container.SetSetLastActivity((Get-Date))
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

        [Parameter(Mandatory = $False)]
        [switch]$IsMounted,

        [switch]$Timestamp
    )

    if($RegistrySubKey -or $KeyId)
    {
        $Container = [Container]::new()
        if($RegistrySubKey) {
            $Container.SetKey($RegistrySubKey)
        } elseif ($KeyId) {
            $Container.SetKeyId($KeyId)
        }

        $Container.OpenTrueCryptKey()

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

        $Container.SetTimestamp($Timestamp)

        # if this is switched (True), that means we dont want to record this activity
        if($NoActivity -eq $False) {
            $Container.SetLastActivity( (Get-Date) )
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