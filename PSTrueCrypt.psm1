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
    Sets in the registry the TrueCrypt container's path and name (that may be used when invoking Mount-TrueCrypt function). 

.DESCRIPTION
    When invoked successfully, the container's path, preferred mount drive letter (if given), and a name (if given) will be stored
    as a subkey in the HKEY_LOCAL_MACHINE\SOFTWARE\PSTrueCrypt registry key (which will be created if it doesn't exists).

.PARAMETER Path
    The TrueCrypt container's location.

.PARAMETER Name
    A name to be used to reference this container.

.PARAMETER Letter
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
function Set-TrueCryptContainer
{
	[CmdletBinding()]
	param(
	  [Parameter(Mandatory=$True,Position=1)]
	   [string]$Path,
	   
	  [Parameter(Mandatory=$False)]
	   [string]$Name,

	  [Parameter(Mandatory=$False)]
       [string]$Letter
	)

    begin {
        # check to see if a subkey exists, if not create one and return item...
        $PSTrueCrypt = Get-HKCUSoftwareKey -Name "PSTrueCrypt"
        
        $PSTrueCrypt
    }
}

# internal function
function Get-HKCUSoftwareKey
{
	param(
	  [Parameter(Mandatory=$True,Position=1)]
	   [string]$Name
	)

    process {
        $SubKey

        try { 
            $SubKey = Get-Item -Path HKCU:\Software\$Name -ErrorAction Stop
        }
        catch {
            $SubKey = New-Item -Path HKCU:\Software\$Name 
        }

        return $SubKey
    }
}

# internal function
function Create-SubKey
{
	param(
	  [Parameter(Mandatory=$True,Position=1)]
	   [string]$Name
	)
    +=$SubKey.SubKeyCount
}

# internal function
function Get-TrueCryptConfigNode
{
	param(
	  [Parameter(Mandatory=$True,Position=1)]
	   [string]$Name
	)

    begin {
        $ErrorActionPreference = "Stop"

        # import config file
        # <configs>
	    #    <config name="Area51" path="D:\Area51" drive="X" />
        # </configs>
        [xml]$ConfigFile = Get-Content $PSScriptRoot"\PSTrueCrypt-Config.xml"
        
        $TargetedConfigNode = $ConfigFile.Configs.Config | Where-Object { $_.name -eq $Name}

        if(-not $ConfigFile.Configs) {
            $ErrorMessage = @"
"You need to add at least one config node in '$PSScriptRoot\PSTrueCrypt-Config.xml' file.  View '$PSScriptRoot\PSTrueCrypt-Config.Sample.xml' as a reference."
"@
            Write-Error $ErrorMessage            
        }
        elseif(-not $TargetedConfigNode.name) {    
            $ErrorMessage = @"
"There was no node found with a name attribute of '$Name' in the '$PSScriptRoot\PSTrueCrypt-Config.xml' file."
"@
            Write-Error $ErrorMessage
        }

        $Settings = @{
            TrueCryptContainerPath = $TargetedConfigNode.path
            PreferredMountDrive = $TargetedConfigNode.drive
        }

        return $Settings
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
Export-ModuleMember -function Set-TrueCryptContainer
Export-ModuleMember -function Get-HKCUSoftwareKey
