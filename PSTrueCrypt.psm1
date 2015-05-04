<#
.SYNOPSIS
Mounts a TrueCrypt container using config settings in the config file and credentials from Windows Credential Manager.

.DESCRIPTION
After editing PSTrueCrypt-Config.xml file and adding a password to Windows Credential Manager, you will be able to mount 
a TrueCrypt container (assuming TrueCrypt is installed).  This method of mounting and dismounting a TrueCrypt container
does not require and GUI, its all done in PowerShell!

.PARAMETER Name
The name attribute value of the config element.

.PARAMETER KeyfilePath
Any path(s) to keyfiles (or directories) if required.

.EXAMPLE
PS C:\>Mount-TrueCrypt -Name Area51

.EXAMPLE
PS C:\>Mount-TrueCrypt -Name Area51 -KeyfilePath C:/Music/Louie_Louie.mp3

.INPUTS
System.String

.OUTPUTS
None

.NOTES
To add Windows Credentials, open up Control Panel>User Accounts>Credential Manager and click "Add a gereric credential". 
The "Internet or network address" field must equal the credential attribute in a the config node.

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

        # construct arguements and execute expression...
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
Dismounts a TrueCrypt container using config settings in the config file.

.DESCRIPTION
After editing PSTrueCrypt-Config.xml file and adding a password to Windows Credential Manager, you will be able to mount 
a TrueCrypt container (assuming TrueCrypt is installed).  This method of mounting and dismounting a TrueCrypt container
does not require and GUI, its all done in PowerShell!

.PARAMETER Name
The name attribute value of the config element.

.EXAMPLE
PS C:\>Dismount-TrueCrypt -Name Area51

.INPUTS
System.String

.OUTPUTS
None

.NOTES
To add Windows Credentials, open up Control Panel>User Accounts>Credential Manager and click "Add a gereric credential". 
The "Internet or network address" field must equal the credential attribute in a the config node.
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
        if($Force -eq $False) {
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
        
        $TargetedConfigNode = $ConfigFile.Configs.Config | ? { $_.name -eq $Name}

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
            $KeyfilePath | % { 
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

# http://www.jonathanmedd.net/2014/01/testing-for-admin-privileges-in-powershell.html
function Test-IsAdmin {
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

Export-ModuleMember -function Mount-TrueCrypt
Export-ModuleMember -function Dismount-TrueCrypt