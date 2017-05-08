---
external help file: PSTrueCrypt-help.xml
online version: https://github.com/marckassay/PSTrueCrypt
schema: 2.0.0
---

# New-PSTrueCryptContainer

## SYNOPSIS
Sets in the registry the TrueCrypt container's location, preferred mount drive letter, and name.

## SYNTAX

```
New-PSTrueCryptContainer [-Name] <String> [-Location] <String> [-MountLetter] <String> [-Product] <String>
 [-Timestamp]
```

## DESCRIPTION
When invoked successfully, the container's: location, preferred mount drive letter, and name will be stored as a subkey in the HKCU:\Software\PSTrueCrypt registry key. 
If call for first time, PSTrueCrypt registry key will be created.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
Adds settings for PSTrueCrypt.
```
PS C:\\\>New-PSTrueCryptContainer -Name Kryptos -Location D:\Kryptos -MountLetter F -Product TrueCrypt
```


## PARAMETERS

### -Name
An arbitrary name to reference this setting when using Mount-TrueCrypt or Dismount-TrueCrypt.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Location
The TrueCrypt container's location.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MountLetter
A preferred mount drive letter for this container.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Product
Specifies if the container has been created with TrueCrypt or VeraCrypt.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Timestamp
This switch will update the container's last write time. 
This is particularly useful when the container resides in  a cloud storage service such as: 'Dropbox', 'Google Drive' or 'OneDrive'.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### None

## OUTPUTS

### None

## NOTES

## RELATED LINKS

