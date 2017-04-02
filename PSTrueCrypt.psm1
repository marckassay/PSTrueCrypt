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
	param(
	  [Parameter(Mandatory=$True,Position=1)]
	   [string]$Name,
	   
	  [Parameter(Mandatory=$False)]
	   [array]$KeyfilePath,

	  [Parameter(Mandatory=$False)]
	   [System.Security.SecureString]$Password
	)

    begin {
        
        # if no password was given, then we need to start the process for of prompting for one...
        if([string]::IsNullOrEmpty($Password) -eq $True) {

            $WasConsolePromptingPrior

            # check to see if session is in admin mode for console prompting...
            if(Test-IsAdmin -eq $True) { 
                $WasConsolePromptingPrior = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds" | Select-Object -ExpandProperty ConsolePrompting

                Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds" -Name ConsolePrompting -Value $True
            }

        }

        $Settings = Get-TrueCryptConfigNode -Name $Name
    }

    process {

        # get password string...
        if([string]::IsNullOrEmpty($Password) -eq $True) {
            $Password = Read-Host -Prompt "Enter password" -AsSecureString
        }

        $Credentials = New-Object System.Management.Automation.PSCredential("nil", $Password)
        $PasswordString = $Credentials.GetNetworkCredential().Password

        # construct arguments and execute expression...
        [string]$TrueCryptParams = Get-TrueCryptMountParams -Password $PasswordString -TrueCryptContainerPath $Settings.TrueCryptContainerPath -PreferredMountDrive $Settings.PreferredMountDrive -KeyfilePath $KeyfilePath
        
        $Expression = $TrueCryptParams.Insert(0,"& TrueCrypt ")
        
        Invoke-Expression $Expression
    }

    end {
        
        # if console prompting was set to false prior to this module, then set it back to false... 
        if($WasConsolePromptingPrior -eq $False) {
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
	param(
	  [Parameter(Mandatory=$False,Position=1)]
	   [string]$Name,

	   [switch]$ForceAll
	)

    begin { 

        $Settings
        # is Dismount-TrueCrypt has been invoked with the -Force flag, then it will have a value of true..
        if($ForceAll -eq $False) {
            $Settings = Get-TrueCryptConfigNode -Name $Name
            
            # construct arguments and execute expression...
            [string]$TrueCryptParams = Get-TrueCryptDismountParams -Drive $Settings.PreferredMountDrive
        } else {
            # construct arguments for Force dismount(s)...
            [string]$TrueCryptParams = Get-TrueCryptDismountParams -Drive ""
        }
    }

    process {

        $Expression = $TrueCryptParams.Insert(0,"& TrueCrypt ")
        
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
	param(
	  [Parameter(Mandatory=$True,Position=1)]
	   [string]$Location,
	   
	  [Parameter(Mandatory=$True)]
	   [string]$Name,

	  [Parameter(Mandatory=$False)]
       [string]$MountLetter
	)

    begin {

        $Key
        $SubKey

        $rule = New-Object System.Security.AccessControl.RegistryAccessRule (
		    [System.Security.Principal.WindowsIdentity]::GetCurrent().Name,"FullControl",
		    [System.Security.AccessControl.InheritanceFlags]"ObjectInherit,ContainerInherit",
		    [System.Security.AccessControl.PropagationFlags]"None",
		    [System.Security.AccessControl.AccessControlType]"Allow")

        Push-Location
        Set-Location HKCU:\SOFTWARE
    }

    process {

        try {
            $Key = Get-Item -Path "PSTrueCrypt"

            if($Key -eq $null) {
                throw [System.IO.FileNotFoundException]
            }
        } catch {
            $Key = New-Item -Path "PSTrueCrypt"
        }

        [string]$SubKeyName = New-Guid

		$SubKey = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey("SOFTWARE\PSTrueCrypt\$SubKeyName",
					[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree)

        $acl = $SubKey.GetAccessControl()
		$acl.SetAccessRule($rule)
		$SubKey.SetAccessControl($acl)
        
        New-ItemProperty -Path  "PSTrueCrypt\$SubKeyName" -Name Location    -PropertyType String -Value $Location
        New-ItemProperty -Path  "PSTrueCrypt\$SubKeyName" -Name Name        -PropertyType String -Value $Name
        New-ItemProperty -Path  "PSTrueCrypt\$SubKeyName" -Name MountLetter -PropertyType String -Value $MountLetter
    }

    end {

        Pop-Location

        return $SubKey
    }
}

function Remove-PSTrueCryptContainer
{
	[CmdletBinding()]
	param(
	  [Parameter(Mandatory=$True,Position=1)]
	   [string]$Name
	)

    begin {
        Push-Location
        Set-Location -Path HKCU:\SOFTWARE\PSTrueCrypt

        $PSChildName
        Get-ChildItem . -Recurse | ForEach-Object {
           if($Name -eq (Get-ItemProperty $_.PsPath).Name) {
            $PSChildName = $_.PSChildName
           }
        }

        [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKey("SOFTWARE\PSTrueCrypt\$PSChildName",
			[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree)

        Pop-Location
    }
}

function Show-PSTrueCryptContainers
{
    begin {
        Push-Location
        Set-Location -Path HKCU:\SOFTWARE\PSTrueCrypt

        Get-ChildItem . -Recurse | ForEach-Object {
            Get-ItemProperty $_.PsPath
        } | Format-Table Name, MountLetter, Location -AutoSize

        Pop-Location
    }
}

# internal function
function Get-TrueCryptMountParams
{
    param(
	  [Parameter(Mandatory=$True,Position=1)]
	   [string]$Password,

	  [Parameter(Mandatory=$True,Position=2)]
	   [string]$TrueCryptContainerPath,

	  [Parameter(Mandatory=$True,Position=3)]
	   [string]$PreferredMountDrive,
	   
	  [Parameter(Mandatory=$false,Position=4)]
	   [array]$KeyfilePath
    )

    process {

        $ParamsHash = @{
            "/quit"="";
            "/v"=$TrueCryptContainerPath;
            "/l"=$PreferredMountDrive;
            "/a"="";
            "/p"="'$Password'";
            "/e"="";
        }
		
        if($KeyfilePath.count -gt 0) {
            $KeyfilePath | For-Each { 
                $ParamsHash.Add("/keyfile","'$_'")
            }
        }
        
        $ParamsString = New-Object -TypeName "System.Text.StringBuilder";

        $ParamsHash.GetEnumerator() | ForEach-Object {
            if($_.Value.Equals("")) {
                [void]$ParamsString.AppendFormat("{0}", $_.Key)
            } else {
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
    param(
	  [Parameter(Mandatory=$False,Position=1)]
	   [string]$Drive
    )

    process {

        $ParamsHash = @{
            "/quit"="";
            "/d"=$Drive;
        }
        
        # Force dismount for all TrueCrypt volumes? ...
        if($Drive -eq "") {
            $ParamsHash.Add("/f","")
        }

        $ParamsString = New-Object -TypeName "System.Text.StringBuilder";

        $ParamsHash.GetEnumerator() | ForEach-Object {
            if($_.Value.Equals("")) {
                [void]$ParamsString.AppendFormat("{0}", $_.Key)
            } else {
                [void]$ParamsString.AppendFormat("{0} {1}", $_.Key, $_.Value)
            }

            [void]$ParamsString.Append(" ")
        }
        
        return $ParamsString.ToString().TrimEnd(" ");
    }
}


# internal function
# ref: http://www.jonathanmedd.net/2014/01/testing-for-admin-privileges-in-powershell.html
function Test-IsAdmin {
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

Export-ModuleMember -function Mount-TrueCrypt
Export-ModuleMember -function Dismount-TrueCrypt
Export-ModuleMember -function New-PSTrueCryptContainer
Export-ModuleMember -function Remove-PSTrueCryptContainer
Export-ModuleMember -function Show-PSTrueCryptContainers