---
external help file: PSTrueCrypt-help.xml
online version: https://github.com/marckassay/PSTrueCrypt
schema: 2.0.0
---

# Remove-PSTrueCryptContainer

## SYNOPSIS
Remove settings that were added by the New-PSTrueCryptContainer function.

## SYNTAX

```
Remove-PSTrueCryptContainer [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION
Remove the subkey in the HKCU:\Software\PSTrueCrypt registry, that contains the value of Name parameter.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
C:\> Remove-PSTrueCryptContainer -Name Kryptos
```

## PARAMETERS

### -Name
The name that is used to reference this setting for Mount-TrueCrypt or Dismount-TrueCrypt functions.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### None

## NOTES

## RELATED LINKS

