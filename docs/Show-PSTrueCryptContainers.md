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
Show-PSTrueCryptContainers [<CommonParameters>]
```

## DESCRIPTION
When this parameterless function is called, a list is displayed in the command-line shell for all subkey registries under the HKCU:\Software\PSTrueCrypt registry key.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
C:\> Show-PSTrueCryptContainers
 Name  Location                      MountLetter Product
 ----  --------                      ----------- -------
 brian C:\passwords                  X           VeraCrypt
 verac D:\veracrypt                  V           VeraCrypt
 lori  D:\Documents                  H           TrueCrypt
 1pw   F:\Google Drive\1pw           Z           TrueCrypt

C:\> 
```

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### None

## NOTES

## RELATED LINKS

