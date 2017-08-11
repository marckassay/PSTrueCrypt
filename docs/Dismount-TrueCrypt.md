---
external help file: PSTrueCrypt-help.xml
online version: https://github.com/marckassay/PSTrueCrypt
schema: 2.0.0
---

# Dismount-TrueCrypt

## SYNOPSIS
Dismounts a TrueCrypt container.

## SYNTAX

```
Dismount-TrueCrypt [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION
In order to use this function, you must provide container settings that will be added to the local registry. 
You can add container settings via New-PSTrueCryptContainer.

The default Alias name is: dmt

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
C:\> Dismount-TrueCrypt -Name Kryptos
```

## PARAMETERS

### -Name
The name attribute value of the that was used in mounting the container.

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

