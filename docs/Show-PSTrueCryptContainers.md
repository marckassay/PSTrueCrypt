---
external help file: PSTrueCrypt-help.xml
online version: https://github.com/marckassay/PSTrueCrypt
schema: 2.0.0
---

# Show-PSTrueCryptContainers

## SYNOPSIS
Displays all settings for mounting and dismounting.

## SYNTAX

```
Show-PSTrueCryptContainers
```

## DESCRIPTION
When this parameterless function is called, a list is displayed in the command-line shell for all subkey registries under the HKCU:\Software\PSTrueCrypt registry key.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
Displays all added PSTrueCrypt containers.  These were added by the New-PSTrueCryptContainer
```
PS C:\>Show-PSTrueCryptContainers
 Name  Location                      MountLetter Product
 ----  --------                      ----------- -------
 brian C:\passwords                  X           VeraCrypt
 verac D:\veracrypt                  V           VeraCrypt
 lori  D:\Documents                  H           TrueCrypt
 1pw   F:\Google Drive\1pw           Z           TrueCrypt

PS C:\>
```


## PARAMETERS

## INPUTS

### None

## OUTPUTS

### None

## NOTES

## RELATED LINKS

