---
external help file: PSTrueCrypt-help.xml
online version: https://github.com/marckassay/PSTrueCrypt
schema: 2.0.0
---

# Edit-PSTrueCryptContainer

## SYNOPSIS
Edits a PSTrueCryptContainer in the registry with any of the following values: Name, Location, MountLetter, Product and Timestamp

## SYNTAX

```
Edits-PSTrueCryptContainer [-Name] <String> [-Location] <String> [-MountLetter] <String> [-Product] <String>
 [-Timestamp] [<CommonParameters>]
```

## DESCRIPTION
Edits a PSTrueCryptContainer in the registry with any of the following values: Name, Location, MountLetter, Product and Timestamp

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
C:\> Edit-PSTrueCryptContainer Kriptos -Name Kryptos
```

### -------------------------- EXAMPLE 2 --------------------------
```
C:\> Edit-PSTrueCryptContainer Kryptos -Location D:\Kryptos -MountLetter F -Timestamp
```

## PARAMETERS

### -Name
The existing name to reference this setting. If you want to 

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
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

Required: False
Position: Named
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

Required: False
Position: Named
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

Required: False
Position: Named
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### None

## NOTES

## RELATED LINKS

