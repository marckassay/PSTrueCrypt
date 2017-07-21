function Get-RegistrySubKeys
{
    [CmdletBinding()]
    [OutputType([PsObject])]
    Param
    (
        [Parameter(Mandatory = $False)]
        [ScriptBlock]$FilterScript
    )

    begin
    {
        if($SUT -eq $False) {
            Push-Location
            
            Set-Location -Path HKCU:\SOFTWARE\PSTrueCrypt
            
            Start-Transaction
        }
    }

    process
    {
        try 
        {
            $RegistrySubKeys = Get-ChildItem . -Recurse -UseTransaction

            if($FilterScript) {
                $RegistrySubKeys = $RegistrySubKeys | Where-Object -FilterScript $FilterScript
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
        if($SUT -eq $False) {
            Pop-Location
                        
            Complete-Transaction
        }

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
        if($SUT -eq $False) {
            Push-Location
            
            Set-Location -Path HKCU:\SOFTWARE\PSTrueCrypt
            
            Start-Transaction
        }
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
        if($SUT -eq $False) {
            Pop-Location
        
            Complete-Transaction
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
        [string]$Name
    )

    begin
    {
        if($SUT -eq $False) {
            Push-Location
            
            Set-Location -Path HKCU:\SOFTWARE\PSTrueCrypt
            
            Start-Transaction
        }
    }

    process
    {
        try 
        {
            if($Id) {
                if((Get-ItemPropertyValue -Path $_.PSChildName -Name PSChildName -UseTransaction) -eq $Id) {
                    $FoundKey = $_
                }
            } elseif($Name) {
                if((Get-ItemPropertyValue -Path $_.PSChildName -Name Name -UseTransaction) -eq $Name) {
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
        if($SUT -eq $False) {
            Pop-Location
        
            Complete-Transaction
        }

        $FoundKey
    }
}

function Remove-SubKeyByPropertyValue
{
    [CmdletBinding()]
    [OutputType([void])]
    Param
    (
        [Parameter(Mandatory = $False)]
        [string]$Id,

        [Parameter(Mandatory = $False)]
        [string]$Name
    )

    begin
    {
        if($SUT -eq $False) {
            Push-Location
            
            Set-Location -Path HKCU:\SOFTWARE\PSTrueCrypt
            
            Start-Transaction
        }
    }
    
    process
    {
        try 
        {
            if($Id) {
                Get-RegistrySubKeys | Get-SubKeyByPropertyValue -Name $Id | Remove-Item -Path $_.PSPath -Recurse
            } elseif($Name) {
                Get-RegistrySubKeys | Get-SubKeyByPropertyValue -Name $Name | Remove-Item -Path $_.PSPath -Recurse
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
        if($SUT -eq $False) {
            Pop-Location
        
            Complete-Transaction
        }
    }
}

#internal function
function Get-PSTrueCryptContainer 
{
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    $SubKeyName = Get-SubKeyPath -Name $Name | Select-Object -ExpandProperty PSChildName

    if($SubKeyName)
    {
        $Settings = @{
            KeyId                   = $SubKeyName
            TrueCryptContainerPath  = Get-ItemProperty  "HKCU:\SOFTWARE\PSTrueCrypt\$SubKeyName" | Select-Object -ExpandProperty Location
            PreferredMountDrive     = Get-ItemProperty  "HKCU:\SOFTWARE\PSTrueCrypt\$SubKeyName" | Select-Object -ExpandProperty MountLetter
            Product                 = Get-ItemProperty  "HKCU:\SOFTWARE\PSTrueCrypt\$SubKeyName" | Select-Object -ExpandProperty Product
            LastActivity            = Get-ItemProperty  "HKCU:\SOFTWARE\PSTrueCrypt\$SubKeyName" | Select-Object -ExpandProperty LastActivity
            Timestamp               = [bool](Get-ItemProperty  "HKCU:\SOFTWARE\PSTrueCrypt\$SubKeyName" | Select-Object -ExpandProperty Timestamp)
            IsMounted               = [bool](Get-ItemProperty  "HKCU:\SOFTWARE\PSTrueCrypt\$SubKeyName" | Select-Object -ExpandProperty IsMounted)
        }
    }
    else
    {
        Out-Error 'UnableToFindPSTrueCryptContainer' -Format $Name -Action Stop
    }

    $Settings
}

function Set-PSTrueCryptContainer 
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$SubKeyName,

        [Parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()]
        [DateTime]$LastActivity,

        [Parameter(Mandatory = $False)]
        [ValidateNotNull()]
        [bool]$IsMounted = $False,

        [Parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()]
        [string]$LastMountedUri
    )

    if($SUT -eq $False) {
        Push-Location
        
        Set-Location -Path HKCU:\SOFTWARE\PSTrueCrypt
        
        Start-Transaction
    }

    try
    {
        Set-ItemProperty -Path $SubKeyName -Name IsMounted -Value $IsMounted.GetHashCode() -UseTransaction 
        Set-ItemProperty -Path $SubKeyName -Name LastActivity -Value $LastActivity -UseTransaction
        if($LastMountedUri) {
            Set-ItemProperty -Path $SubKeyName -Name LastMountedUri -Value $LastMountedUri -UseTransaction
        }
    }
    catch
    {
        Out-Error 'UnableToWriteRegistry' -Format $Name -Action Stop
    }

    if($SUT -eq $False) {
        Complete-Transaction

        Pop-Location
    }
}

Export-ModuleMember -Function Get-RegistrySubKeys
Export-ModuleMember -Function Get-SubKeyNames
Export-ModuleMember -Function Get-SubKeyByPropertyValue
Export-ModuleMember -Function Remove-SubKeyByPropertyValue