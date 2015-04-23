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
	   
	  [Parameter(Mandatory=$False,Position=2)]
	   [array]$KeyfilePath
	)

    begin {
        Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds" -Name ConsolePrompting -Value $True

        $Settings = Get-TrueCryptConfigNode -Name $Name
    }

    process {

        $Credentials = Get-Credential $Settings.WindowsCredentialName
        $Password = $Credentials.GetNetworkCredential().Password

        [string]$TrueCryptParams = Get-TrueCryptParams -Password $Password -TrueCryptContainerPath $Settings.TrueCryptContainerPath -PreferredMountDrive $Settings.PreferredMountDrive -KeyfilePath $KeyfilePath
        
        $Expression = $TrueCryptParams.Insert(0,"& TrueCrypt ")
        
        Invoke-Expression $Expression
    }

    end {
        $Password = ""
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

function Get-TrueCryptParams
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
                $ParamsHash.Add("/keyfile",$_)
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

Export-ModuleMember -function Mount-TrueCrypt
Export-ModuleMember -function Dismount-TrueCrypt