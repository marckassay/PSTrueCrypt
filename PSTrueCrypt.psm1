<#
.SYNOPSIS
    Mounts a TrueCrypt container. 

.DESCRIPTION
    In order to use this function, there must be a file in this module directory named, 'PSTrueCrypt-Config.xml'.  This file must contain a config node referencing the TrueCrypt container with a drive letter.

.PARAMETER Name
    The name attribute value of the config node.

.PARAMETER KeyfilePath
    Any path(s) to keyfiles (or directories) if required.

.PARAMETER Password
    If invoking this function in a background task, give value to this parameter to prevent function from prompting user for password.

.EXAMPLE
    Mounts a TrueCrypt container with name of 'Area51' which must be in the 'PSTrueCrypt-Config.xml'.

    PS C:\>Mount-TrueCrypt -Name Area51

.EXAMPLE
    Mounts a TrueCrypt container with name of 'Area51' that requires a Keyfile.

    PS C:\>Mount-TrueCrypt -Name Area51 -KeyfilePath C:/Music/Louie_Louie.mp3

.EXAMPLE
    Mounts a TrueCrypt container with name of 'Area51' that requires a Keyfile and passes a secure password into the Password parameter.  This is usefull for background tasks that can't rely on user input.

    PS C:\>$SecurePassword = "123abc" | ConvertTo-SecureString -AsPlainText -Force
    PS C:\>Mount-TrueCrypt -Name Area51 -KeyfilePath C:/Music/Louie_Louie.mp3 -Password $SecurePassword

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

    Begin
    {
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
    }

    Process
    {
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
    }

    End
    {
        # if console prompting was set to false prior to this module, then set it back to false... 
        if ($WasConsolePromptingPrior -eq $False)
        {
            Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds" -Name ConsolePrompting -Value $False
        }

        $PasswordString = ""
    }
}

<#
.SYNOPSIS
    Dismounts a TrueCrypt container. 

.DESCRIPTION
    In order to use this function, there must be a file in this module directory named, 'PSTrueCrypt-Config.xml'.  This file must contain a config node referencing the TrueCrypt container with a drive letter.

.PARAMETER Name
    The name attribute value of the config node.

.PARAMETER ForceAll
    If method is invoked with this flag/switch parameter, TrueCrypt will force (discard any unsaved changes) dismount of all TrueCrypt containers.

.EXAMPLE
    Dismounts a TrueCrypt container with name of 'Area51' which must be in the 'PSTrueCrypt-Config.xml'.

    PS C:\>Dismount-TrueCrypt -Name Area51

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
        [string]$Name,

        [switch]$ForceAll
    )

    Begin
    { 
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
    }

    Process
    {
        $Expression = $TrueCryptParams.Insert(0, "& TrueCrypt ")
        
        Invoke-Expression $Expression 
    }
}


<#
.SYNOPSIS
    Sets in the registry the TrueCrypt container's location and name (that may be used when invoking Mount-TrueCrypt function). 

.DESCRIPTION
    When invoked successfully, the container's location, preferred mount drive letter (if given), and a name will be stored
    as a subkey in the HKCU:\Software\PSTrueCrypt registry key (which will be created if it doesn't exists).

.PARAMETER Location
    The TrueCrypt container's location.

.PARAMETER Name
    A name to be used to reference this container.

.PARAMETER MountLetter
    A preferred mount drive letter for this container.

.EXAMPLE
    Dismounts a TrueCrypt container with name of 'Area51' which must be in the 'PSTrueCrypt-Config.xml'.

    PS C:\>Dismount-TrueCrypt -Name Area51

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
function New-PSTrueCryptContainer
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$Location,
	   
        [Parameter(Mandatory = $True)]
        [string]$Name,

        [Parameter(Mandatory = $True)]
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
        
    New-ItemProperty -Path  "HKCU:\SOFTWARE\PSTrueCrypt\$SubKeyName" -Name Location    -PropertyType String -Value $Location
    New-ItemProperty -Path  "HKCU:\SOFTWARE\PSTrueCrypt\$SubKeyName" -Name Name        -PropertyType String -Value $Name
    New-ItemProperty -Path  "HKCU:\SOFTWARE\PSTrueCrypt\$SubKeyName" -Name MountLetter -PropertyType String -Value $MountLetter
}

function Remove-PSTrueCryptContainer 
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$Name
    )

    [System.String]$PSChildName = Get-SubKeyPath -Name $Name
    $PSChildName                = $PSChildName.TrimStart()
       
    try 
    {
        [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKey("SOFTWARE\PSTrueCrypt\$PSChildName", $True)
    }
    catch 
    {
        
    }
}

function Show-PSTrueCryptContainers 
{
    Push-Location
    Set-Location -Path HKCU:\SOFTWARE\PSTrueCrypt

    Get-ChildItem . -Recurse | ForEach-Object {
        Get-ItemProperty $_.PsPath
    } | Format-Table Name, MountLetter, Location -AutoSize

    Pop-Location
}

#internal function
function Get-PSTrueCryptContainer 
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$Name
    )

    [System.String]$SubKeyName  = Get-SubKeyPath -Name $Name
    $SubKeyName                 = $SubKeyName.TrimStart()

    $Settings = @{
                    TrueCryptContainerPath = Get-ItemProperty "HKCU:\SOFTWARE\PSTrueCrypt\$SubKeyName" | Select-Object -ExpandProperty Location
                    PreferredMountDrive = Get-ItemProperty "HKCU:\SOFTWARE\PSTrueCrypt\$SubKeyName" | Select-Object -ExpandProperty MountLetter
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

    Get-ChildItem . -Recurse | ForEach-Object {
        if ($Name -eq (Get-ItemProperty $_.PsPath).Name) 
        {
            $PSChildName = $_.PSChildName
        }
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

    Process
    {
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
}

# internal function
function Get-TrueCryptDismountParams
{
    Param
    (
        [Parameter(Mandatory = $False, Position = 1)]
        [string]$Drive
    )

    Process
    {
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