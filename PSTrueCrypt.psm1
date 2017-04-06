<#
.SYNOPSIS
    Mounts a TrueCrypt container. 

.DESCRIPTION
    In order to use this function, you must provide container settings that will be added to the local registry.  You can add container 
    settings via New-PSTrueCryptContainer.

.PARAMETER Name
    The name attribute value of the container settings that was added to the registry.  Call Show-PSTrueCryptContainers to displayed all 
    container settings.

.PARAMETER KeyfilePath
    Any path(s) to keyfiles (or directories) if required.

.PARAMETER Password
    If invoking this function in a background task, give value to this parameter to prevent function from prompting user for password. See
    the third example that is in this function's header comment.

.EXAMPLE
    Mounts a TrueCrypt container with name of 'Kryptos' must be in the registry.

    PS C:\>Mount-TrueCrypt -Name Kryptos

.EXAMPLE
    Mounts a TrueCrypt container with name of 'Kryptos' that requires a Keyfile.

    PS C:\>Mount-TrueCrypt -Name Kryptos -KeyfilePath C:/Music/Courage.mp3

.EXAMPLE
    Mounts a TrueCrypt container with name of 'Kryptos' that requires a Keyfile and passes a secure password into the Password parameter.  
    This is usefull for background tasks that can't rely on user input.

    PS C:\>$SecurePassword = "123abc" | ConvertTo-SecureString -AsPlainText -Force
    PS C:\>Mount-TrueCrypt -Name Kryptos -KeyfilePath C:/Music/Courage.mp3 -Password $SecurePassword

.INPUTS
    None

.OUTPUTS
    None

.LINK
    https://github.com/marckassay/PSTrueCrypt
#>
function Mount-TrueCrypt
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$Name,

        [Parameter(Mandatory = $False)]
        [array]$KeyfilePath,

        [Parameter(Mandatory = $False)]
        [System.Security.SecureString]$Password
    )

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
    }

    $Settings = Get-PSTrueCryptContainer -Name $Name

    # get password string...
    if ([string]::IsNullOrEmpty($Password) -eq $True)
    {
        $Password = Read-Host -Prompt "Enter password" -AsSecureString
    }

    $Credentials = New-Object System.Management.Automation.PSCredential("nil", $Password)
    $PasswordString = $Credentials.GetNetworkCredential().Password

    # construct arguments and execute expression...
    [string]$TrueCryptParams = Get-TrueCryptMountParams -Password $PasswordString -TrueCryptContainerPath $Settings.TrueCryptContainerPath -PreferredMountDrive $Settings.PreferredMountDrive -KeyfilePath $KeyfilePath
    
    $Expression = $TrueCryptParams.Insert(0, "& TrueCrypt ")
    
    Invoke-Expression $Expression

    # if console prompting was set to false prior to this module, then set it back to false... 
    if ($WasConsolePromptingPrior -eq $False)
    {
        Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds" -Name ConsolePrompting -Value $False
    }

    $PasswordString = ""
}

<#
.SYNOPSIS
    Dismounts a TrueCrypt container. 

.DESCRIPTION
    In order to use this function, you must provide container settings that will be added to the local registry.  You can add container 
    settings via New-PSTrueCryptContainer.

.PARAMETER Name
    The name attribute value of the that was used in mounting the container.

.PARAMETER ForceAll
    If method is invoked with this switch (flag) parameter, TrueCrypt will force (discard any unsaved changes) dismount of all TrueCrypt containers.

.EXAMPLE
    Dismounts a TrueCrypt container with name of 'Kryptos' which must be in the container settings.

    PS C:\>Dismount-TrueCrypt -Name Kryptos

.EXAMPLE
    Dismounts all TrueCrypt containers

    PS C:\>Dismount-TrueCrypt -ForceAll

.INPUTS
    None

.OUTPUTS
    None

.LINK
    https://github.com/marckassay/PSTrueCrypt
#>
function Dismount-TrueCrypt
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $False, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [switch]$ForceAll
    )

    $Settings

    # is Dismount-TrueCrypt has been invoked with the -Force flag, then it will have a value of true..
    if ($ForceAll -eq $False)
    {
        $Settings = Get-PSTrueCryptContainer -Name $Name
        
        # construct arguments and execute expression...
        [string]$TrueCryptParams = Get-TrueCryptDismountParams -Drive $Settings.PreferredMountDrive
    }
    else
    {
        # construct arguments for Force dismount(s)...
        [string]$TrueCryptParams = Get-TrueCryptDismountParams -Drive ""
    }

    $Expression = $TrueCryptParams.Insert(0, "& TrueCrypt ")
    
    Invoke-Expression $Expression
}


<#
.SYNOPSIS
    Sets in the registry the TrueCrypt container's location, preferred mount drive letter, and name. 

.DESCRIPTION
    When invoked successfully, the container's: location, preferred mount drive letter, and name will be stored
    as a subkey in the HKCU:\Software\PSTrueCrypt registry key.  If call for first time, PSTrueCrypt registry key
    will be created.

.PARAMETER Location
    The TrueCrypt container's location.

.PARAMETER Name
    An arbitrary name to reference this setting when using Mount-TrueCrypt or Dismount-TrueCrypt.

.PARAMETER MountLetter
    A preferred mount drive letter for this container.

.EXAMPLE
    Adds settings for PSTrueCrypt.

    PS C:\>New-PSTrueCryptContainer -Location D:\Kryptos -Name Kryptos -MountLetter F

.INPUTS
    None

.OUTPUTS
    None

.LINK
    https://github.com/marckassay/PSTrueCrypt
#>
function New-PSTrueCryptContainer
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Location,

        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$MountLetter
    )

    $AccessRule = New-Object System.Security.AccessControl.RegistryAccessRule (
        [System.Security.Principal.WindowsIdentity]::GetCurrent().Name, "FullControl",
        [System.Security.AccessControl.InheritanceFlags]"ObjectInherit,ContainerInherit",
        [System.Security.AccessControl.PropagationFlags]"None",
        [System.Security.AccessControl.AccessControlType]"Allow")

    [System.String]$SubKeyName = New-Guid

    $SubKey = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey("SOFTWARE\PSTrueCrypt\$SubKeyName",
              [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree)

    $AccessControl = $SubKey.GetAccessControl()
    $AccessControl.SetAccessRule($AccessRule)
    $SubKey.SetAccessControl($AccessControl)

    try 
    {
        New-ItemProperty -Path  "HKCU:\SOFTWARE\PSTrueCrypt\$SubKeyName" -Name Location    -PropertyType String -Value $Location
        New-ItemProperty -Path  "HKCU:\SOFTWARE\PSTrueCrypt\$SubKeyName" -Name Name        -PropertyType String -Value $Name
        New-ItemProperty -Path  "HKCU:\SOFTWARE\PSTrueCrypt\$SubKeyName" -Name MountLetter -PropertyType String -Value $MountLetter
    }
    catch 
    {
        
    }
}


<#
.SYNOPSIS
    Remove settings that were added by the New-PSTrueCryptContainer function.

.DESCRIPTION
    Remove the subkey in the HKCU:\Software\PSTrueCrypt registry, that contains the value of Name parameter.

.PARAMETER Name
    The name that is used to reference this setting for Mount-TrueCrypt or Dismount-TrueCrypt functions. 

.EXAMPLE
    Remove-PSTrueCryptContainer -Name Kryptos

.INPUTS
    None

.OUTPUTS
    None

.LINK
    https://github.com/marckassay/PSTrueCrypt
#>
function Remove-PSTrueCryptContainer 
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    [System.String]$PSChildName = Get-SubKeyPath -Name $Name
    $PSChildName                = $PSChildName.TrimStart() # unsure why there is a space at the start?
       
    try 
    {
        [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKey("SOFTWARE\PSTrueCrypt\$PSChildName", $True)
    }
    catch 
    {
        
    }
}


<#
.SYNOPSIS
    Displays all settings for mounting and dismounting.

.DESCRIPTION
    When this parameterless function is called, a list is displayed in the command-line shell for all subkey registries
    under the HKCU:\Software\PSTrueCrypt registry key.

.INPUTS
    None

.OUTPUTS
    None

.LINK
    https://github.com/marckassay/PSTrueCrypt
#>
function Show-PSTrueCryptContainers 
{
    Push-Location
    Set-Location -Path HKCU:\SOFTWARE\PSTrueCrypt

    try 
    {
        Get-ChildItem . -Recurse | ForEach-Object {
            Get-ItemProperty $_.PsPath
        }| Format-Table Name, MountLetter, Location -AutoSize
    }
    catch
    {
        
    }

    Pop-Location
}

#internal function
function Get-PSTrueCryptContainer 
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    [System.String]$SubKeyName  = Get-SubKeyPath -Name $Name
    $SubKeyName                 = $SubKeyName.TrimStart() # unsure why there is a space at the start?

    try 
    {
        $Settings = @{
            TrueCryptContainerPath = Get-ItemProperty "HKCU:\SOFTWARE\PSTrueCrypt\$SubKeyName" | Select-Object -ExpandProperty Location
            PreferredMountDrive = Get-ItemProperty "HKCU:\SOFTWARE\PSTrueCrypt\$SubKeyName" | Select-Object -ExpandProperty MountLetter
                    }
    }
    catch
    {
        
    }

    $Settings
}

# internal function
function Get-SubKeyPath
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True)]
        [string]$Name
    )

    Push-Location
    Set-Location -Path HKCU:\SOFTWARE\PSTrueCrypt

    $PSChildName

    try 
    {
        Get-ChildItem . -Recurse | ForEach-Object {
            if ($Name -eq (Get-ItemProperty $_.PsPath).Name) 
            {
                $PSChildName = $_.PSChildName
            }
        }
    }
    catch 
    {
        
    }

    Pop-Location

    $PSChildName
}

# internal function
function Get-TrueCryptMountParams 
{
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$Password,

        [Parameter(Mandatory = $True, Position = 2)]
        [string]$TrueCryptContainerPath,

        [Parameter(Mandatory = $True, Position = 3)]
        [string]$PreferredMountDrive,
	   
        [Parameter(Mandatory = $false, Position = 4)]
        [array]$KeyfilePath
    )

    $ParamsHash = @{
                        "/quit" = "";
                        "/v" = $TrueCryptContainerPath;
                        "/l" = $PreferredMountDrive;
                        "/a" = "";
                        "/p" = "'$Password'";
                        "/e" = "";
                    }

    if ($KeyfilePath.count -gt 0) 
    {
        $KeyfilePath | For-Each 
        { 
            $ParamsHash.Add("/keyfile", "'$_'")
        }
    }
    
    $ParamsString = New-Object -TypeName "System.Text.StringBuilder";

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
    
    return $ParamsString.ToString().TrimEnd(" ");
}

# internal function
function Get-TrueCryptDismountParams
{
    Param
    (
        [Parameter(Mandatory = $False, Position = 1)]
        [string]$Drive
    )

    $ParamsHash = @{
                    "/quit" = "";
                    "/d" = $Drive;
                    }
    
    # Force dismount for all TrueCrypt volumes? ...
    if ($Drive -eq "") 
    {
        $ParamsHash.Add("/f", "")
    }

    $ParamsString = New-Object -TypeName "System.Text.StringBuilder";

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
    
    return $ParamsString.ToString().TrimEnd(" ");
}

# internal function
# ref: http://www.jonathanmedd.net/2014/01/testing-for-admin-privileges-in-powershell.html
function Test-IsAdmin 
{
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

Export-ModuleMember -function Mount-TrueCrypt
Export-ModuleMember -function Dismount-TrueCrypt
Export-ModuleMember -function New-PSTrueCryptContainer
Export-ModuleMember -function Remove-PSTrueCryptContainer
Export-ModuleMember -function Show-PSTrueCryptContainers