using namespace 'System.Management.Automation'
using module .\src\CIM\PSTrueCrypt.CIM.psm1
using module .\src\Storage\PSTrueCrypt.Storage.psm1
using module .\src\Utility\PSTrueCrypt.Utility.psm1
using module .\src\Writer\PSTrueCrypt.Writer.psm1
using module .\src\PSTrueCrypt.CommandLine.psm1

$SUT = $False

#.ExternalHelp PSTrueCrypt-help.xml
function Mount-TrueCrypt
{
    [CmdletBinding(PositionalBinding=$False)]
    Param
    (
        [Parameter(Mandatory = $False)]
        [array]$KeyfilePath,

        [Parameter(Mandatory = $False)]
        [System.Security.SecureString]$Password
    )

    DynamicParam
    {
        return Get-DynamicParameterValues
    }
    
    process
    {
        try 
        {
            $Settings = Get-PSTrueCryptContainer -Name $PSBoundParameters.Name
        }
        catch [ItemNotFoundException]
        {
            Out-Error 'NoPSTrueCryptContainerFound' -Action Stop
        }

        # construct arguments for expression and insert token in for password...
        [string]$Expression = Get-TrueCryptMountParams  -TrueCryptContainerPath $Settings.TrueCryptContainerPath -PreferredMountDrive $Settings.PreferredMountDrive -Product $Settings.Product -KeyfilePath $KeyfilePath -Timestamp $Settings.Timestamp

        # if no password was given, then we need to start the process for of prompting for one...
        if ([string]::IsNullOrEmpty($Password) -eq $True)
        {
            $WasConsolePromptingPrior
            # check to see if session is in admin mode for console prompting...
            if (Test-IsAdmin -eq $True)
            {
                $WasConsolePromptingPrior = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds" | Select-Object -ExpandProperty ConsolePrompting

                Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds" -Name ConsolePrompting -Value $True
            }

            [securestring]$Password = Read-Host -Prompt "Enter password" -AsSecureString
        }

        # this method of handling password securely has been mentioned at the following links:
        # https://msdn.microsoft.com/en-us/library/system.security.securestring(v=vs.110).aspx
        # https://msdn.microsoft.com/en-us/library/system.runtime.interopservices.marshal.securestringtobstr(v=vs.110).aspx
        # https://msdn.microsoft.com/en-us/library/system.intptr(v=vs.110).aspx
        # https://msdn.microsoft.com/en-us/library/ewyktcaa(v=vs.110).aspx
        try
        {
            # Create IntPassword and dispose $Password...

            [System.IntPtr]$IntPassword = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
        }
        catch [System.NotSupportedException]
        {
            # The current computer is not running Windows 2000 Service Pack 3 or later.
            Out-Error 'NotSupportedException'
        }
        catch [System.OutOfMemoryException]
        {
            # OutOfMemoryException
            Out-Error 'OutOfMemoryException'
        }
        finally
        {
            $Password.Dispose()
        }

        Start-CimLogicalDiskWatch $Settings.KeyId -InstanceType 'Creation'

        try
        {
            # Execute Expression
            Invoke-Expression ($Expression -f [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($IntPassword))
        }
        catch [System.Exception]
        {
            Out-Error 'UnknownException', 'EnsureFileRecommendment'
        }
        finally
        { 
        # TODO: this is crashing CLS.  Is this to be called when dismount is done?  Perhaps TrueCrypt is 
        # holding on to this pointer while container is open.
        # [System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemAnsi($IntPassword)
        }

        # if console prompting was set to false prior to this module, then set it back to false... 
        if ($WasConsolePromptingPrior -eq $False)
        {
            Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds" -Name ConsolePrompting -Value $False
        }

        if($KeyfilePath -ne $null)
        {
            Edit-HistoryFile -KeyfilePath $KeyfilePath
        }
    }
}

#.ExternalHelp PSTrueCrypt-help.xml
function Dismount-TrueCrypt
{
    [CmdletBinding()]
    Param()

    DynamicParam
    {
        return Get-DynamicParameterValues
    }
    
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
        $Container = Get-RegistrySubKeys | Get-SubKeyByPropertyValue -Name $PSBoundParameters.Name | Read-Container
        
        Start-CIMLogicalDiskWatch $Container.Id -InstanceType 'Deletion'

        # construct arguments and execute expression...
        [string]$Expression = Get-TrueCryptDismountParams -Drive $Container.MountLetter -Product $Container.Product

        Invoke-Expression $Expression
    }

    end
    {
        if($SUT -eq $False) {
            Pop-Location

            Complete-Transaction
        }
    }
}


#.ExternalHelp PSTrueCrypt-help.xml
function Dismount-TrueCryptForceAll
{
    Invoke-DismountAll -Product TrueCrypt
    Invoke-DismountAll -Product VeraCrypt
}

# internal function
function Invoke-DismountAll
{
    [CmdletBinding()]
    Param
    (
        [ValidateSet("TrueCrypt", "VeraCrypt")]
        [string]$Product
    )

    # construct arguments for Force dismount(s)...
    [string]$Expression = Get-TrueCryptDismountParams -Product $Product

    try
    {
        Invoke-Expression $Expression
        $HasXCryptDismountFailed = $False
    }
    catch 
    {
        $HasXCryptDismountFailed = $True
    }
    finally
    {
        if($HasXCryptDismountFailed -eq $False)
        {
            Out-Information 'AllProductContainersDismounted' -Format $Product
        }
        else 
        {
            Out-Error 'DismountException' -Format $Product
        }
    }
}

#.ExternalHelp PSTrueCrypt-help.xml
function New-PSTrueCryptContainer
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

    $SubKeyName = Get-SubKeyPath -Name $Name

    if(-not ($SubKeyName) )
    {
        $Decision = Get-Confirmation -Message "New-PSTrueCryptContainer will add a new subkey in the following of your registry: HKCU:\SOFTWARE\PSTrueCrypt"

        $CreationDate = Get-Date

        try
        {
            if ($Decision -eq $True)
            {
                [System.String]$NewSubKeyName = New-Guid
                $AccessRule = New-Object System.Security.AccessControl.RegistryAccessRule (
                    [System.Security.Principal.WindowsIdentity]::GetCurrent().Name, "FullControl",
                    [System.Security.AccessControl.InheritanceFlags]"ObjectInherit,ContainerInherit",
                    [System.Security.AccessControl.PropagationFlags]"None",
                    [System.Security.AccessControl.AccessControlType]"Allow")

                $SubKey = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey("SOFTWARE\PSTrueCrypt\$NewSubKeyName",
                        [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree)

                $AccessControl = $SubKey.GetAccessControl()
                $AccessControl.SetAccessRule($AccessRule)
                $SubKey.SetAccessControl($AccessControl)

                # slient out-put using '[void](...)'
                [void](New-ItemProperty -Path  "HKCU:\SOFTWARE\PSTrueCrypt\$NewSubKeyName" -Name Name        -PropertyType String -Value $Name)
                [void](New-ItemProperty -Path  "HKCU:\SOFTWARE\PSTrueCrypt\$NewSubKeyName" -Name Location    -PropertyType String -Value $Location)
                [void](New-ItemProperty -Path  "HKCU:\SOFTWARE\PSTrueCrypt\$NewSubKeyName" -Name MountLetter -PropertyType String -Value $MountLetter)
                [void](New-ItemProperty -Path  "HKCU:\SOFTWARE\PSTrueCrypt\$NewSubKeyName" -Name Product     -PropertyType String -Value $Product)
                [void](New-ItemProperty -Path  "HKCU:\SOFTWARE\PSTrueCrypt\$NewSubKeyName" -Name Timestamp   -PropertyType DWord -Value $Timestamp.GetHashCode())
                [void](New-ItemProperty -Path  "HKCU:\SOFTWARE\PSTrueCrypt\$NewSubKeyName" -Name IsMounted   -PropertyType DWord -Value $False.GetHashCode())
                [void](New-ItemProperty -Path  "HKCU:\SOFTWARE\PSTrueCrypt\$NewSubKeyName" -Name LastActivity -PropertyType String -Value $CreationDate)

                Out-Information 'NewContainerOperationSucceeded' -Format $Name
            }
            else
            {
                Out-Warning 'NewContainerOperationCancelled'
            }
        }
        catch [System.UnauthorizedAccessException]
        {
            # TODO: append to this message of options for a solution.  solution will be determined if the user is in an elevated CLS.
            Out-Error 'UnauthorizedAccessException'
        }
    } else {
         Out-Warning 'ContainerNameAlreadyExists' -Format $Name
    }
}


#.ExternalHelp PSTrueCrypt-help.xml
function Remove-PSTrueCryptContainer 
{
    [CmdletBinding()]
    Param () # value is selected from DynamicParam block

    DynamicParam
    {
        return Get-DynamicParameterValues
    }
    
    process
    {
        try
        {
            $Decision = Get-Confirmation -Message "Remove-PSTrueCryptContainer will remove the $PSBoundParameters.Name"+" from your registry: HKCU:\SOFTWARE\PSTrueCrypt"

            if ($Decision -eq $True)
            {
                Remove-SubKeyByPropertyValue -Name $PSBoundParameters.Name

                Out-Information 'ContainerSettingsDeleted'
            } 
            else 
            {
                Out-Information 'RemoveContainerOperationCancelled'
            }
        }
        catch [System.ObjectDisposedException]
        {
            #The RegistryKey being manipulated is closed (closed keys cannot be accessed).
            Out-Error 'ObjectDisposedException'
        }
        catch [System.ArgumentException],[System.ArgumentNullException]
        {
            #subkey does not specify a valid registry key, and throwOnMissingSubKey is true.
            #subkey is null.
            Out-Error 'UnableToFindPSTrueCryptContainer' -Format $PSBoundParameters.Name

        }
        catch [System.Security.SecurityException]
        {
            #The user does not have the permissions required to delete the key.
            Out-Error 'SecurityException' -Recommendment 'SecurityRecommendment'
        }
        catch [System.InvalidOperationException]
        {
            # subkey has child subkeys.
            Out-Error 'InvalidOperationException'
        }
        catch [System.UnauthorizedAccessException]
        {
            #The user does not have the necessary registry rights.
            Out-Error 'UnauthorizedRegistryAccessException'
        }
        catch
        {
            Out-Error 'UnknownException'
        }
    }
}


#.ExternalHelp PSTrueCrypt-help.xml
function Show-PSTrueCryptContainers 
{
    [CmdletBinding()]
    Param ()

    if($SUT -eq $False) {
        Push-Location
        
        Set-Location -Path HKCU:\SOFTWARE\PSTrueCrypt
        
        Start-Transaction
    }

    try 
    {
        Restart-LogicalDiskCheck
        
        $OutVar = Get-ChildItem . -Recurse -UseTransaction | ForEach-Object {
            Get-ItemProperty $_.PsPath -UseTransaction
        } | Sort-Object Name
        
        if($OutVar) {
            Format-Table Name, Location, MountLetter, Product, @{Label="Timestamp";Expression={[bool]($_.Timestamp)}}, @{Label="IsMounted";Expression={[bool]($_.IsMounted)}}, @{Label="Last Activity";Expression={[DateTime]($_.LastActivity)}} -AutoSize -InputObject $OutVar
        } else {
            Out-Information 'NoPSTrueCryptContainerFound'
        }
    }
    catch [System.Security.SecurityException]
    {
        #The user does not have the permissions required to delete the key.
        Out-Error 'SecurityException' -Recommendment 'SecurityRecommendment'
    }

    if($SUT -eq $False) {
        Complete-Transaction

        Pop-Location
    } else {
        $OutVar
    }
}

Set-Alias -Name mt -Value Mount-TrueCrypt
Set-Alias -Name dmt -Value Dismount-TrueCrypt
Set-Alias -Name dmt* -Value Dismount-TrueCryptForceAll

Start-SystemCheck