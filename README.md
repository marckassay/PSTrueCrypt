# PSTrueCrypt
PSTrueCrypt is a PowerShell module to mount and dismount TrueCrypt containers.  

Features:
* No configuration files are needed
* Supports the use of keyfiles
* Dismounts all TrueCrypt containers with one command


## Instructions
* Download project to your PowerShell Module directory.  Or if PsGet is installed run the following command:
	```
	Install-Module PSTrueCrypt
	```
### Usage:
* Mount-TrueCrypt
	```
	E:\> Mount-TrueCrypt -Name marc
	Enter password: **********
	E:\>
	```

* Dismount-TrueCrypt
	```
	E:\> Dismount-TrueCrypt -Name marc
	E:\>
	```

* New-PSTrueCryptContainer
	```
	E:\> New-PSTrueCryptContainer -Name marc -Location D:\Kryptos -MountLetter M

	New-PSTrueCryptContainer will add a new subkey in the following of your registry: HKCU:\SOFTWARE\PSTrueCrypt
	Are you sure you want to proceed?
	[Y] Yes  [N] No  [?] Help (default is "N"): Y

	E:\>
	```

* Remove-PSTrueCryptContainer
	```
	E:\> Remove-PSTrueCryptContainer -Name marc
	Container settings has been deleted from registry.
	
	E:\>
	```

* Show-PSTrueCryptContainers
	```
	E:\> Show-PSTrueCryptContainers

	Name  MountLetter Location
	----  ----------- --------
	brian B           D:\Passwords
	marc  M           D:\Kryptos
	lori  L           D:\Documents

	E:\>
	```

### Roadmap
* Add tab completion (via PSReadLine) for container settings in the registry
* Add the ability to use without registry.
* Add functionality to attempt to resolve conflicts.
