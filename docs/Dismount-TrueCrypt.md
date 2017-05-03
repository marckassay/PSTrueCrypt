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
Dismount-TrueCrypt [[-Name] <String>] [-ForceAll]
```

## DESCRIPTION
In order to use this function, you must provide container settings that will be added to the local registry. 
You can add container  settings via New-PSTrueCryptContainer.

The default Alias name is: dt

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Dismounts a TrueCrypt container with name of 'Kryptos' which must be in the container settings.
```

PS C:\\\>Dismount-TrueCrypt -Name Kryptos

### -------------------------- EXAMPLE 2 --------------------------
```
Dismounts all TrueCrypt containers
```

PS C:\\\>Dismount-TrueCrypt -ForceAll

## PARAMETERS

### -Name
The name attribute value of the that was used in mounting the container.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ForceAll
If method is invoked with this switch (flag) parameter, TrueCrypt will force (discard any unsaved changes) dismount of all TrueCrypt containers.

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

