# PSTrueCrypt
PSTrueCrypt is a Powershell module to interact with TrueCrypt.  TrueCrypt passwords are handled via Windows Credential Manager.

Public functions are Mount-TrueCrypt and Dismount-TrueCrypt.

## Instructions
* Download project to your Powershell Module directory.  Or if PsGet is installed run the following command:
	Install-Module PSTrueCrypt
* Copy-and-paste PSTrueCrypt-Config.Sample.xml file, rename it to 'PSTrueCrypt-Config'.
* Add TrueCrypt password to Windows Credential Manager.  To add Windows Credentials, open up Control Panel>User Accounts>Credential Manager and click "Add a generic credential".  The "Internet or network address" field must equal the credential attribute in a the config node.
* Mount TrueCrypt container
![screenshot of mounting TrueCrypt container](screenshot_1.png)

### Roadmap
* Add tab completion (via PSReadLine) for config settings
* Add functionality to automate adding Windows Credentials
