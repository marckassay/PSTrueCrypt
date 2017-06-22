using namespace 'System.Management.Automation'
using module .\src\writer\Error.psm1
using module .\src\writer\Information.psm1
using module .\src\writer\Verbose.psm1
using module .\src\writer\Warning.psm1
using module .\src\utils\CIMLogicalDiskWatcher.ps1
using module .\src\utils\common.ps1

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
        $ContainerNames = Get-ContainerNames

        $ParamAttrib = New-Object ParameterAttribute
        $ParamAttrib.Mandatory = $True
        $ParamAttrib.Position = 0

        $AttribColl = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $AttribColl.Add((New-Object ValidateSetAttribute($ContainerNames)))
        $AttribColl.Add($ParamAttrib)

        $RuntimeParam = New-Object RuntimeDefinedParameter('Name', [string], $AttribColl)
        $RuntimeParamDic = New-Object RuntimeDefinedParameterDictionary
        $RuntimeParamDic.Add('Name', $RuntimeParam)

        return $RuntimeParamDic
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

        Start-CIMLogicalDiskWatch -SubKeyName $Settings.KeyId

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
        $ContainerNames = Get-ContainerNames

        $ParamAttrib = New-Object ParameterAttribute
        $ParamAttrib.Mandatory = $True
        $ParamAttrib.Position = 0

        $AttribColl = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $AttribColl.Add((New-Object ValidateSetAttribute($ContainerNames)))
        $AttribColl.Add($ParamAttrib)

        $RuntimeParam = New-Object RuntimeDefinedParameter('Name', [string], $AttribColl)
        $RuntimeParamDic = New-Object RuntimeDefinedParameterDictionary
        $RuntimeParamDic.Add('Name', $RuntimeParam)

        return $RuntimeParamDic
    }
    
    process
    {
        $Settings = Get-PSTrueCryptContainer -Name $PSBoundParameters.Name
        
        # construct arguments and execute expression...
        [string]$Expression = Get-TrueCryptDismountParams -Drive $Settings.PreferredMountDrive -Product $Settings.Product

        Invoke-Expression $Expression
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

        $LookingTo=Get-Date # :/

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
                [void](New-ItemProperty -Path  "HKCU:\SOFTWARE\PSTrueCrypt\$NewSubKeyName" -Name LastActivity -PropertyType QWord -Value $LookingTo)

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
    Param ()

    DynamicParam
    {
        $ContainerNames = Get-ContainerNames

        $ParamAttrib = New-Object ParameterAttribute
        $ParamAttrib.Mandatory = $True
        $ParamAttrib.Position = 0

        $AttribColl = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $AttribColl.Add((New-Object ValidateSetAttribute($ContainerNames)))
        $AttribColl.Add($ParamAttrib)

        $RuntimeParam = New-Object RuntimeDefinedParameter('Name', [string], $AttribColl)
        $RuntimeParamDic = New-Object RuntimeDefinedParameterDictionary
        $RuntimeParamDic.Add('Name', $RuntimeParam)

        return $RuntimeParamDic
    }
    
    process
    {
        try
        {
            $SubKeyName = Get-SubKeyPath -Name $PSBoundParameters.Name

            if($SubKeyName)
            {
                $Decision = Get-Confirmation -Message "Remove-PSTrueCryptContainer will remove a subkey from your registry: HKCU:\SOFTWARE\PSTrueCrypt"

                if ($Decision -eq $True)
                {
                    Remove-HKCUSubKey $SubKeyName

                    Out-Information 'ContainerSettingsDeleted'
                } 
                else 
                {
                    Out-Information 'RemoveContainerOperationCancelled'
                }
            }
            else
            {
                throw New-Object System.ArgumentException('UnableToFindPSTrueCryptContainer')
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
            Timestamp               = (Get-ItemProperty  "HKCU:\SOFTWARE\PSTrueCrypt\$SubKeyName" | Select-Object -ExpandProperty Timestamp) -eq 1
            IsMounted               = (Get-ItemProperty  "HKCU:\SOFTWARE\PSTrueCrypt\$SubKeyName" | Select-Object -ExpandProperty IsMounted) -eq 1
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
        [bool]$IsMounted = $False
    )

    if($SUT -eq $False) {
        Push-Location
        
        Set-Location -Path HKCU:\SOFTWARE\PSTrueCrypt
        
        Start-Transaction
    }

    try
    {
        [void](Set-ItemProperty -Path $SubKeyName -Name IsMounted -Value $IsMounted.GetHashCode() -UseTransaction)
        [void](Set-ItemProperty -Path $SubKeyName -Name LastActivity -Value $LastActivity -UseTransaction)
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

# internal function
function Get-TrueCryptMountParams 
{
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$TrueCryptContainerPath,

        [Parameter(Mandatory = $True, Position = 2)]
        [string]$PreferredMountDrive,

        [Parameter(Mandatory = $True, Position = 3)]
        [string]$Product,

        [Parameter(Mandatory = $False, Position = 4)]
        [array]$KeyfilePath,

        [Parameter(Mandatory = $False, Position = 5)]
        [bool]$Timestamp
    )

    $ParamsHash = @{
                        "/quit" = "";
                        "/volume" = "'$TrueCryptContainerPath'";
                        "/letter" = "'$PreferredMountDrive'";
                        "/auto" = "";
                        "/password" = "'{0}'";
                        "/explore" = "";
                    }

    $ParamsString = New-Object -TypeName "System.Text.StringBuilder";

    [void]$ParamsString.Insert(0, "& "+$Product+" ")

    if ($Timestamp) 
    {
        $ParamsHash.Add("/mountoption", "timestamp")
    }

    # add keyfile(s) if any to ParamsHash...
    if ($KeyfilePath.count -gt 0) 
    {
        $KeyfilePath | ForEach-Object { 
            $ParamsHash.Add("/keyfile", "'$_'")
        }
    }
    
    # populate ParamsString with ParamsHash data...
    $ParamsHash.GetEnumerator() | ForEach-Object {
        # if no value assigned to this TrueCrypt attribute, then just append attribute to ParamsString...
        if ($_.Value.Equals(""))
        {
            [void]$ParamsString.AppendFormat("{0}", $_.Key)
        }
        else
        {
            [void]$ParamsString.AppendFormat("{0} {1}", $_.Key, $_.Value)
        }

        [void]$ParamsString.Append(" ")
    }
    
    $ParamsString.ToString().TrimEnd(" ");
}


# internal function
function Get-TrueCryptDismountParams
{
    Param
    (
        [Parameter(Mandatory = $False)]
        [string]$Drive,

        [Parameter(Mandatory = $True)]
        [string]$Product
    )

    $ParamsHash = @{
                    "/quit" = "";
                    "/dismount" = $Drive
                }
    
    # Force dismount for all TrueCrypt volumes? ...
    if($Drive -eq "")
    {
        $ParamsHash.Add("/force", "")
    }

    $ParamsString = New-Object -TypeName "System.Text.StringBuilder";

    [void]$ParamsString.Insert(0, "& "+$Product+" ")

    $ParamsHash.GetEnumerator() | ForEach-Object {
        if ($_.Value.Equals("")) 
        {
            [void]$ParamsString.AppendFormat("{0}", $_.Key)
        }
        else
        {
            [void]$ParamsString.AppendFormat("{0} {1}", $_.Key, $_.Value)
        }

        [void]$ParamsString.Append(" ")
    }
    
    return $ParamsString.ToString().TrimEnd(" ")
}

# TODO:  since the interals of this have changed, we remove this. if so, update tests.
# internal function: designed for Pester access
function Remove-HKCUSubKey
{
    Param
    (
        [object]$FullPath
    )
    # the CurrentUser here indicates HKEY_CURRENT_USER hive...
    Remove-Item $FullPath.PSPath -Recurse
}

# internal function
# returns the path to the subkey: 'HKCU:\SOFTWARE\PSTrueCrypt\e03e195e-c069-4c6b-9d35-6b61cdf40aad'
function Get-SubKeyPath
{
    Param
    (
        [Parameter(Mandatory = $True)]
        [string]$Name
    )

    Push-Location
    Set-Location -Path HKCU:\SOFTWARE\PSTrueCrypt

    try 
    {
        Get-ChildItem . -Recurse | ForEach-Object {if($Name -eq (Get-ItemProperty $_.PsPath).Name){
            $PSChildName = $_
        }}
    }
    catch 
    {
        # TODO: Need to throw specific error to calling method
        Out-Error 'UnableToReadRegistry'
    }
    finally
    {
        Pop-Location

        $PSChildName
    }
}

function Get-ContainerNames
{
    Push-Location
    Set-Location -Path HKCU:\SOFTWARE\PSTrueCrypt

    try 
    {
        $ContainerNames = Get-ChildItem . -Recurse | ForEach-Object {
            Get-ItemProperty $_.PsPath
        }| Sort-Object Name | Select-Object -ExpandProperty Name
    }
    catch [System.Security.SecurityException]
    {
        # TODO: Need to throw specific error to calling method
        Out-Error 'UnableToReadRegistry'
    }
    finally
    {
        Pop-Location

        $ContainerNames
    }
}