---
external help file: PSTrueCrypt-help.xml
online version: https://github.com/marckassay/PSTrueCrypt
schema: 2.0.0
---

# Mount-TrueCrypt

## SYNOPSIS
Mounts a TrueCrypt container.

## SYNTAX

```
Mount-TrueCrypt [-KeyfilePath <Array>] [-Password <SecureString>] [-Name] <String>
```

## DESCRIPTION
In order to use this function, you must provide container settings that will be added to the local registry. 
You can add container  settings via New-PSTrueCryptContainer.

The default Alias name is: mt

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
PS C:\\\>Mount-TrueCrypt -Name Kryptos
```

### -------------------------- EXAMPLE 2 --------------------------
```
PS C:\\\>Mount-TrueCrypt -Name Kryptos -KeyfilePath C:/Music/Courage.mp3
```

### -------------------------- EXAMPLE 3 --------------------------
```
PS C:\\\>$SecurePassword = "123abc" | ConvertTo-SecureString -AsPlainText -Force
PS C:\\\>Mount-TrueCrypt -Name Kryptos -KeyfilePath C:/Music/Courage.mp3 -Password $SecurePassword
```

## PARAMETERS

### -Name
The name attribute value of the container settings that was added to the registry. 
Call Show-PSTrueCryptContainers to displayed all  container settings.

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

### -KeyfilePath
Any path(s) to keyfiles (or directories) if required.

```yaml
Type: Array
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Password
If invoking this function in a background task, give value to this parameter to prevent function from prompting user for password.
See the third example that is in this function's header comment.

```yaml
Type: SecureString
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
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

