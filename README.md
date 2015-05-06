# PSTrueCrypt
PSTrueCrypt is a PowerShell module to mount and dismount TrueCrypt containers.  

Public functions are Mount-TrueCrypt and Dismount-TrueCrypt.  

Mount-TrueCrypt supports Keyfile path(s) if needed.  

Dismount-TrueCrypt supports force dismounting of all TrueCrypt containers.

## Instructions
* Download project to your PowerShell Module directory.  Or if PsGet is installed run the following command:
	
	Install-Module PSTrueCrypt
	
* Copy-and-paste PSTrueCrypt-Config.Sample.xml file, rename it to 'PSTrueCrypt-Config'.
* Mount TrueCrypt container
![screenshot of mounting TrueCrypt container](screenshot_1.png)

### Roadmap
* Add tab completion (via PSReadLine) for config settings
