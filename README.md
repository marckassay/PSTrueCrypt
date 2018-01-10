# PSTrueCrypt

PSTrueCrypt is a PowerShell module for mounting TrueCrypt and VeraCrypt containers.

[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/marckassay/PSTrueCrypt/blob/master/LICENSE) [![PS Gallery](https://img.shields.io/badge/install-PS%20Gallery-blue.svg)](https://www.powershellgallery.com/packages/PSTrueCrypt/) [![Build status](https://ci.appveyor.com/api/projects/status/1dnmc2xm6k4s3pjh/branch/master?svg=true)](https://ci.appveyor.com/project/marckassay/pstruecrypt/branch/master)

## Features

* No configuration files are needed.  Registry is used to store non-sensitive data for the container.
* Option to update container's last write time upon dismount. This allows cloud storage services to detect a change for upload.
* Uses SecureString and binary string (BSTR) to handle password securely
* Supports the use of keyfiles
* On PowerShell startup, a test will be made to ensure that TrueCrypt and/or VeraCrypt are set in the system environment 'path' variable

## Limitations

* No support for full disk/partition or system encryption

* TrueCrypt or VeraCrypt must be installed

## Notes

* Only tested on Windows 10 using .NET 4.6

* Help documentation has been generated by [platyPS](https://github.com/PowerShell/platyPS)

* One love, one heart (One repository, one contributor).  So there are most likely unknown limitations and issues.

Please add any feedback, concerns, requests and/or bugs in the 'Issues' section of this repository.

## Instructions

To install with PowerShellGet or PsGet run the following command below.  Or download project to your PowerShell Module directory.

```powershell
Install-Module PSTrueCrypt
```

### Mount-TrueCrypt

Mounts a TrueCrypt container with name of 'Kryptos', which must be in the registry.

```powershell
$ Mount-TrueCrypt -Name Kryptos
Enter password: **********
```

Although not recommended, due to plain-text password variable, this demostrates passing a variable into the Mount-TrueCrypt function.

```powershell
$ $SecurePassword = "123abc" | ConvertTo-SecureString -AsPlainText -Force
$ Mount-TrueCrypt -Name Kryptos -Password $SecurePassword
```

Mounts a TrueCrypt container with name of 'Kryptos' that requires a Keyfile.

```powershell
$ Mount-TrueCrypt -Name Kryptos -KeyfilePath C:/Music/Outshined.mp3
Enter password: **********
```

### Dismount-TrueCrypt

```powershell
$ Dismount-TrueCrypt -Name Kryptos
```

Using the alias for Dismount-TrueCryptForceAll, dismounts all TrueCrypt and all VeraCrypt containers respectively.

```powershell
$ dmt*
All TrueCrypt containers have successfully dismounted.  Please verify.
All VeraCrypt containers have successfully dismounted.  Please verify.
```

### New-PSTrueCryptContainer

Creates a container setting in the registry, specifying 'Kryptos' for the name which is referenced by PSTrueCrypt. And specifying the path to the container at 'D:\Kryptos' with 'M' being the letter of the drive.  And claiming the container having been created with VeraCrypt.

```powershell
$ New-PSTrueCryptContainer -Name Kryptos -Location D:\Kryptos -MountLetter M -Product VeraCrypt

New-PSTrueCryptContainer will add a new subkey in the following of your registry: HKCU:\SOFTWARE\PSTrueCrypt
Are you sure you want to proceed?
[Y] Yes  [N] No  [?] Help (default is "N"): Y
'Krytos' PSTrueCrypt container has been created!
```

Identical as the example directly above except the 'Timestamp' switch parameter is being used to indicate that
the container's 'Last Write Time' should be updated when dismounted.  This is particularly useful if the container resides
in a cloud storage service directory.

```powershell
$ New-PSTrueCryptContainer -Name Kryptos -Location D:\Kryptos -MountLetter M -Product VeraCrypt -Timestamp

New-PSTrueCryptContainer will add a new subkey in the following of your registry: HKCU:\SOFTWARE\PSTrueCrypt
Are you sure you want to proceed?
[Y] Yes  [N] No  [?] Help (default is "N"): Y
'Krytos' PSTrueCrypt container has been created!
```

### Edit-PSTrueCryptContainer

Use this function to edit an existing container that has been created with New-PSTrueCryptContainer.

```powershell
$ Edit-PSTrueCryptContainer Bobby -NewName Bob

Name Location                            MountLetter Product   Timestamp
---- --------                            ----------- -------   ---------
Bob  D:\Google Drive\Documents\truecrypt T           TrueCrypt     False

Edit-PSTrueCryptContainer will set Bobby with the above values.
Do you want to proceed?
[Y] Yes  [N] No  [?] Help (default is "N"): Y
'Bob' PSTrueCrypt container has been updated!
```

### Remove-PSTrueCryptContainer

```powershell
$ Remove-PSTrueCryptContainer -Name Kryptos
Remove-PSTrueCryptContainer will remove a subkey from your registry: HKCU:\SOFTWARE\PSTrueCrypt
Are you sure you want to proceed?
[Y] Yes  [N] No  [?] Help (default is "N"): Y
Container settings has been deleted from registry.
```

### Show-PSTrueCryptContainers

```powershell
$ Show-PSTrueCryptContainers

Name   Location                       MountLetter Product   Timestamp IsMounted Last Activity
----   --------                       ----------- -------   --------- --------- ------------------
1pw    D:\Google Drive\Documents\1pw  Y           TrueCrypt      True      True 7/04/2017 06:12:23
Krytos D:\Google Drive\               D           TrueCrypt      True     False 5/10/2017 10:10:30
```