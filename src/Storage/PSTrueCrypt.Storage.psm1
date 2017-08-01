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
                        Write-Information -MessageData "Get-RegistrySubKeys..." -InformationAction Continue

        try 
        {
            if(-not $Path) {
                $Path = Get-Location
            }

            if($FilterScript) {
                Get-ChildItem $Path  | Where-Object -FilterScript $FilterScript -OutVariable $RegistrySubKeys
            } else {
                Get-ChildItem $Path 
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
                    if(($RegistrySubKeys | Get-ItemPropertyValue -Name PSChildName ) -eq $Id) {
                        $FoundKey = $_
                    }
                } elseif($Name) {
                    if(($RegistrySubKeys | Get-ItemPropertyValue -Name Name ) -eq $Name) {
                        $FoundKey = $_
                    }
                } elseif($MountLetter) {
                    if(($RegistrySubKeys | Get-ItemPropertyValue -Name MountLetter ) -eq $MountLetter) {
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
                    if(($RegistrySubKeys | Get-ItemPropertyValue -Name PSChildName ) -eq $Id) {
                         Remove-Item .\$_.PSChildName  -Recurse -Force
                    }
                } elseif($Name) {
                    if((Get-ItemPropertyValue $_.PSChildName -Name Name) -eq $Name) {
                        $RegistrySubKeys | Remove-Item 
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
        [Parameter(Mandatory = $False)]
        [ScriptBlock]$FilterScript
    )

    begin
    {
    
                Write-Information -MessageData "begin >>> $FilterScript " -InformationAction Continue



    }

    process
    {

        if($FilterScript) {

        Write-Information -MessageData "process >>> " -InformationAction Continue
        }        
    }

    end
    {
                Write-Information -MessageData "end >>> " -InformationAction Continue
 
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
      Write-Host " >read-container>>"+$RegistrySubKey
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