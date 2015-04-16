<#
.SYNOPSIS
Mounts a TrueCrypt container using config settings in the config file and credentials from Windows Credential Manager.

.DESCRIPTION


.PARAMETER Name
The name attribute value of the config element.

.EXAMPLE
PS C:\>Mount-TrueCrypt -Name Area51


.INPUTS
System.String

.OUTPUTS
None

.NOTES
To add Windows Credentials, open up Control Panel>User Accounts>Credential Manager and click "Add a gereric credential". 
The "Internet or network address" field must equal the credential attribute in a the config node.

.LINK
???

.ROLE
???

.FUNCTIONALITY
???
    
#>

function Mount-TrueCrypt
{
	[CmdletBinding()]
	param(
	  [Parameter(Mandatory=$True,Position=1)]
	   [string]$Name,
	   
	  [Parameter(Mandatory=$False,Position=2)]
	   [string]$KeyFilePath
	)

    begin {
        Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds" -Name ConsolePrompting -Value $True

        $Settings = Get-TrueCryptConfigNode -Name $Name
    }

    process {
        $Credentials = Get-Credential $Settings.WindowsCredentialName
        $Password = $Credentials.GetNetworkCredential().Password

        & TrueCrypt /quit /v $Settings.TrueCryptContainerPath /l $Settings.PreferredMountDrive /a /p $Password /e /b
    }

    end {
        $Password = ""
    }
}

function Dismount-TrueCrypt
{
	[CmdletBinding()]
	param(
	  [Parameter(Mandatory=$True,Position=1)]
	   [string]$Name
	)

    begin { 
        $Settings = Get-TrueCryptConfigNode -Name $Name
    }

    process {
        & TrueCrypt /quit /d $Settings.PerferredDrive
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
	    #    <config name="Area51" path="D:\Area51" drive="X" credential="Area51" />
        # </configs>
        [xml]$ConfigFile = Get-Content $PSScriptRoot"\PSTrueCrypt-Config.xml"

        $TargetedConfigNode = $ConfigFile.Configs.Config | ? { $_.name -eq $Name}

        if(-not $TargetedConfigNode.name) {
            $ErrorMessage = @"
"There was no node found with a name attribute of '$Name' in the '$PSScriptRoot\TrueCrypt-Config.xml' file."
"@
            Write-Error $ErrorMessage
        }

        $Settings = @{
            TrueCryptContainerPath = $TargetedConfigNode.path
            PreferredMountDrive = $TargetedConfigNode.drive
            WindowsCredentialName = $TargetedConfigNode.credential
        }

        return $Settings
    }
}

Export-ModuleMember -function Mount-TrueCrypt
Export-ModuleMember -function Dismount-TrueCrypt