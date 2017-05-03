---
external help file: PSTrueCrypt-help.xml
online version: https://github.com/marckassay/PSTrueCrypt
schema: 2.0.0
---

# Set-EnvironmentPathVariable

## SYNOPSIS
Sets the TrueCrypt directory in the environment variable field.

## SYNTAX

```
Set-EnvironmentPathVariable [-PathVar] <String>
```

## DESCRIPTION
Will accept TrueCrypt or VeraCrypt directory paths to be used to set the operating system's environment variable.
This is needed when Mount-TrueCrypt or Dismount-TrueCrypt functions are called. 
It will check ParVar parameter to make sure its valid before setting it as an environment variable.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Setting TrueCrypt directory.
```

PS C:\\\>Set-EnvironmentPathVariable 'C:\Program Files\TrueCrypt'

## PARAMETERS

### -PathVar
The directory path where TrueCrypt or VeraCrypt executable resides.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### None

## OUTPUTS

### None

## NOTES

## RELATED LINKS

