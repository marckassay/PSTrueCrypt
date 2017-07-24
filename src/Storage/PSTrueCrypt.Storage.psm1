function Get-RegistrySubKeys
{
    [CmdletBinding()]
    [OutputType([PsObject])]
    Param
    (
        [Parameter(Mandatory = $False)]
        [ScriptBlock]$FilterScript = {}
    )

    begin
    {
        Invoke-BeginBlock
    }

    process
    {
        try 
        {
            Get-ChildItem . -Recurse -UseTransaction | Where-Object -FilterScript $FilterScript
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
        Invoke-EndBlock

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

    begin
    {
        Invoke-BeginBlock
    }

    process
    {
        try 
        {
            $RegistrySubKeys | Get-ItemPropertyValue -Name Name -UseTransaction -PipelineVariable $Names
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
        Invoke-EndBlock
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
        [string]$Name
    )

    begin
    {
        Invoke-BeginBlock
    }

    process
    {
        try 
        {
            if($Id) {
                if(($RegistrySubKeys | Get-ItemPropertyValue -Path $_.PSChildName -Name PSChildName -UseTransaction) -eq $Id) {
                    $FoundKey = $_
                }
            } elseif($Name) {
                if(($RegistrySubKeys | Get-ItemPropertyValue -Path $_.PSChildName -Name Name -UseTransaction) -eq $Name) {
                    $FoundKey = $_
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
        Invoke-EndBlock

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

    begin
    {
        Invoke-BeginBlock
    }
    
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

    end
    {
        Invoke-EndBlock
    }
}

function Invoke-BeginBlock
{
    if($SUT -eq $False) {
        Push-Location
        
        Set-Location -Path HKCU:\SOFTWARE\PSTrueCrypt
        
        Invoke-Transaction
    }
}

function Invoke-EndBlock
{
    if($SUT -eq $False) {
        Pop-Location
    
        Complete-Transaction
    }
}

Export-ModuleMember -Function Get-RegistrySubKeys
Export-ModuleMember -Function Get-SubKeyNames
Export-ModuleMember -Function Get-SubKeyByPropertyValue
Export-ModuleMember -Function Remove-SubKeyByPropertyValue