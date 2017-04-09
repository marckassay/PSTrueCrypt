# PSTrueCrypt
PSTrueCrypt is a PowerShell module to mount and dismount TrueCrypt containers.  

### Features:
* No configuration files are needed.  Registry is used to store non-sensitive data for the container.
* Supports the use of keyfiles
* Uses SecureString and binary string (BSTR) to handle password securely.

### Limitations:
* Only supports TrueCrypt containers.  No support for disk/parition or system encryption.

### Notes:
* Only tested on Windows 10 using .NET 4.6
* One love, one heart.  (I'm unaware of any other users or developers.)  So there are unknown issues.
Please add an issue if found.

## Instructions
* Download project to your PowerShell Module directory.  Or if PsGet is installed run the following command:
	```powershell
	Install-Module PSTrueCrypt
	```

	### Mount-TrueCrypt

	Mounts a TrueCrypt container with name of 'Kryptos', which must be in the registry.
	```powershell
	E:\> Mount-TrueCrypt -Name Kryptos
	Enter password: **********
	E:\>
	```

	Although not recommended, due to plain-text password variable, this demostrates passing a varible into the 
	Mount-TrueCrypt cmdlet. 
	```powershell
	E:\> $SecurePassword = "123abc" | ConvertTo-SecureString -AsPlainText -Force
	E:\> Mount-TrueCrypt -Name Kryptos -Password $SecurePassword
	E:\>
	```

	Mounts a TrueCrypt container with name of 'Kryptos' that requires a Keyfile.
	```powershell
	E:\> Mount-TrueCrypt -Name Kryptos -KeyfilePath C:/Music/Courage.mp3
	Enter password: **********
	E:\>
	```

	### Dismount-TrueCrypt

	```powershell
	E:\> Dismount-TrueCrypt -Name Kryptos
	E:\>
	```

	### New-PSTrueCryptContainer

	```powershell
	E:\> New-PSTrueCryptContainer -Name Kryptos -Location D:\Kryptos -MountLetter M

	New-PSTrueCryptContainer will add a new subkey in the following of your registry: HKCU:\SOFTWARE\PSTrueCrypt
	Are you sure you want to proceed?
	[Y] Yes  [N] No  [?] Help (default is "N"): Y

	E:\>
	```

	### Remove-PSTrueCryptContainer

	```powershell
	E:\> Remove-PSTrueCryptContainer -Name Kryptos
	Container settings has been deleted from registry.
	
	E:\>
	```

	### Show-PSTrueCryptContainers
	
	```powershell
	E:\> Show-PSTrueCryptContainers

	Name     MountLetter Location
	----     ----------- --------
	brian    B           D:\Passwords
	Kryptos  K           D:\Kryptos
	lori     F           D:\Documents

	E:\>
	```

### Roadmap
* Compatible with VeraCrypt (currently in progress)
* Add tab completion (via PSReadLine) for container settings in the registry
* Add the ability to use without registry.
* Add functionality to attempt to resolve conflicts.