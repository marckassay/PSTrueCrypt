#.ExternalHelp PSTrueCrypt-help.xml
function Mount-TrueCrypt
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $False)]
        [array]$KeyfilePath,

        [Parameter(Mandatory = $False)]
        [System.Security.SecureString]$Password
    )
    
    # TODO: need a better way to check for a subkey.  all keys may have been deleted but PSTrueCrypt still exists
    try 
    {
        $Settings = Get-PSTrueCryptContainer -Name $Name
    }
    catch [System.Management.Automation.ItemNotFoundException]
    {
         Write-Message -Type ([MessageType]::Error) -Key 'NoPSTrueCryptContainerFound' -Action ([System.Management.Automation.ActionPreference]::Stop)
    }

    # construct arguments for expression and insert token in for password...
    [string]$Expression = Get-TrueCryptMountParams  -TrueCryptContainerPath $Settings.TrueCryptContainerPath -PreferredMountDrive $Settings.PreferredMountDrive -Product $Settings.Product -KeyfilePath $KeyfilePath -Timestamp $Settings.Timestamp

    # if no password was given, then we need to start the process for of prompting for one...
    if ([string]::IsNullOrEmpty($Password) -eq $True)
    {
        $WasConsolePromptingPrior
        # check to see if session is in admin mode for console prompting...
        if (Test-IsAdmin -eq $True)
        {
            $WasConsolePromptingPrior = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds" | Select-Object -ExpandProperty ConsolePrompting

            Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds" -Name ConsolePrompting -Value $True
        }

        [securestring]$Password = Read-Host -Prompt "Enter password" -AsSecureString
    }

    # this method of handling password securely has been mentioned at the following links:
    # https://msdn.microsoft.com/en-us/library/system.security.securestring(v=vs.110).aspx
    # https://msdn.microsoft.com/en-us/library/system.runtime.interopservices.marshal.securestringtobstr(v=vs.110).aspx
    # https://msdn.microsoft.com/en-us/library/system.intptr(v=vs.110).aspx
    # https://msdn.microsoft.com/en-us/library/ewyktcaa(v=vs.110).aspx
    try
    {
        # Create IntPassword and dispose $Password...

        [System.IntPtr]$IntPassword = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    }
    catch [System.NotSupportedException]
    {
        # The current computer is not running Windows 2000 Service Pack 3 or later.
        Write-Message -Type ([MessageType]::Error) -Key 'NotSupportedException'
    }
    catch [System.OutOfMemoryException]
    {
        # OutOfMemoryException
        Write-Message -Type ([MessageType]::Error) -Key 'OutOfMemoryException'
    }
    finally
    {
        $Password.Dispose()
    }

    try
    {
        # Execute Expression
        Invoke-Expression ($Expression -f [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($IntPassword))
    }
    catch [System.Exception]
    {
        Write-Message -Type ([MessageType]::Error) -Key 'UnknownException' -Action ([System.Management.Automation.ActionPreference]::Continue) -RecommendedAction 'EnsureFileRecommendment'
    }
    finally
    {
    # TODO: this is crashing CLS.  Is this to be called when dismount is done?  Perhaps TrueCrypt is 
    # holding on to this pointer while container is open.
    # [System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemAnsi($IntPassword)
    }

    # if console prompting was set to false prior to this module, then set it back to false... 
    if ($WasConsolePromptingPrior -eq $False)
    {
        Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds" -Name ConsolePrompting -Value $False
    }

    if($KeyfilePath -ne $null)
    {
        Edit-HistoryFile -KeyfilePath $KeyfilePath
    }
}


#.ExternalHelp PSTrueCrypt-help.xml
function Dismount-TrueCrypt
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $False, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [switch]$ForceAll
    )

    # is Dismount-TrueCrypt has been invoked with the -Force flag, then it will have a value of true..
    if ($ForceAll -eq $False)
    {
        $Settings = Get-PSTrueCryptContainer -Name $Name
        
        # construct arguments and execute expression...
        [string]$Expression = Get-TrueCryptDismountParams -Drive $Settings.PreferredMountDrive -Product $Settings.Product

        Invoke-Expression $Expression
    }
    else
    {
        Invoke-DismountAll -Product TrueCrypt
        
        Invoke-DismountAll -Product VeraCrypt
    }
}


#.ExternalHelp PSTrueCrypt-help.xml
function Dismount-TrueCryptForceAll
{
    Dismount-TrueCrypt -ForceAll
}


#.ExternalHelp PSTrueCrypt-help.xml
function New-PSTrueCryptContainer
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $True, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]$Location,

        [Parameter(Mandatory = $True, Position = 3)]
        [ValidateNotNullOrEmpty()]
        [string]$MountLetter,

        [Parameter(Mandatory = $True, Position = 4)]
        [ValidateSet("TrueCrypt", "VeraCrypt")]
        [string]$Product,

        [switch]$Timestamp
    )

    $AccessRule = New-Object System.Security.AccessControl.RegistryAccessRule (
        [System.Security.Principal.WindowsIdentity]::GetCurrent().Name, "FullControl",
        [System.Security.AccessControl.InheritanceFlags]"ObjectInherit,ContainerInherit",
        [System.Security.AccessControl.PropagationFlags]"None",
        [System.Security.AccessControl.AccessControlType]"Allow")

    [System.String]$SubKeyName = New-Guid

    try
    {
        $Decision = Get-Confirmation -Message "New-PSTrueCryptContainer will add a new subkey in the following of your registry: HKCU:\SOFTWARE\PSTrueCrypt"

        if ($Decision -eq $True) 
        {
            $SubKey = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey("SOFTWARE\PSTrueCrypt\$SubKeyName",
                    [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree)
        }
        else
        {
            Write-Message -Type ([MessageType]::Warning) -Key 'NewContainerOperationCancelled'
        }
    }
    catch [System.UnauthorizedAccessException]
    {
        # TODO: append to this message of options for a solution.  solution will be determined if the user is in an elevated CLS.
        Write-Message -Type ([MessageType]::Error) -Key 'UnauthorizedAccessException'
    }

    $AccessControl = $SubKey.GetAccessControl()
    $AccessControl.SetAccessRule($AccessRule)
    $SubKey.SetAccessControl($AccessControl)

    try 
    {
        if ($Decision -eq 0) 
        {
            New-ItemProperty -Path  "HKCU:\SOFTWARE\PSTrueCrypt\$SubKeyName" -Name Name        -PropertyType String -Value $Name       
            New-ItemProperty -Path  "HKCU:\SOFTWARE\PSTrueCrypt\$SubKeyName" -Name Location    -PropertyType String -Value $Location   
            New-ItemProperty -Path  "HKCU:\SOFTWARE\PSTrueCrypt\$SubKeyName" -Name MountLetter -PropertyType String -Value $MountLetter
            New-ItemProperty -Path  "HKCU:\SOFTWARE\PSTrueCrypt\$SubKeyName" -Name Product     -PropertyType String -Value $Product
            New-ItemProperty -Path  "HKCU:\SOFTWARE\PSTrueCrypt\$SubKeyName" -Name Timestamp   -PropertyType DWord -Value $Timestamp.GetHashCode()
        } 
        else
        {
            Write-Message -Type ([MessageType]::Warning) -Key 'NewContainerOperationCancelled'
        }
    }
    catch [System.UnauthorizedAccessException]
    {
        Write-Message -Type ([MessageType]::Error) -Key 'UnauthorizedAccessException'
    }
}


#.ExternalHelp PSTrueCrypt-help.xml
function Remove-PSTrueCryptContainer 
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    [System.String]$SubKeyName = Get-SubKeyPath -Name $Name

    try
    {
        [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKey("SOFTWARE\PSTrueCrypt\$SubKeyName", $True)

        Write-Message -Type ([MessageType]::Information) -Key 'ContainerSettingsDeleted'
    }
    catch [System.ObjectDisposedException]
    {
        #The RegistryKey being manipulated is closed (closed keys cannot be accessed).
        Write-Message -Type ([MessageType]::Error) -Key 'ObjectDisposedException'
    }
    catch [System.ArgumentException],[System.ArgumentNullException]
    {
        #subkey does not specify a valid registry key, and throwOnMissingSubKey is true.
        #subkey is null.
        Write-Message -Type ([MessageType]::Error) -Key 'UnableToFindPSTrueCryptContainer' -Format {$Name}
    }
    catch [System.Security.SecurityException]
    {
        #The user does not have the permissions required to delete the key.
        Write-Message -Type ([MessageType]::Error) -Key 'SecurityException' -RecommendedAction 'SecurityRecommendment'
    }
    catch [System.InvalidOperationException]
    {
        # subkey has child subkeys.
        Write-Message -Type ([MessageType]::Error) -Key 'InvalidOperationException'
    }
    catch [System.UnauthorizedAccessException]
    {
        #The user does not have the necessary registry rights.
        Write-Message -Type ([MessageType]::Error) -Key 'UnauthorizedRegistryAccessException'
    }
}


#.ExternalHelp PSTrueCrypt-help.xml
function Show-PSTrueCryptContainers 
{
    Push-Location
    Set-Location -Path HKCU:\SOFTWARE\PSTrueCrypt

    try 
    {
        Get-ChildItem . -Recurse | ForEach-Object {
            Get-ItemProperty $_.PsPath
        }| Format-Table Name, Location, MountLetter, Product, Timestamp -AutoSize
    }
    catch [System.Security.SecurityException]
    {
        #The user does not have the permissions required to delete the key.
        Write-Message -Type ([MessageType]::Error) -Key 'SecurityException' -RecommendedAction 'SecurityRecommendment'
    }

    Pop-Location
}


#.ExternalHelp PSTrueCrypt-help.xml
function Set-EnvironmentPathVariable
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$PathVar
    )

    [int]$Results = 0

    $Regex = "(\w+)\\?$"

    try 
    {
        ($PathVar -match $Regex)
        $EnvPathName = $Matches[1]
        
        $Results += [OSVerification]::($EnvPathName+"Found")

        $IsValid = Test-Path $PathVar -IsValid
        
        if($IsValid -eq $True) {
            $Results += [OSVerification]::($EnvPathName+"Valid")
        }

        $IsVerified = Test-Path $PathVar
            
        if($IsVerified -eq $True) {
            $Results += [OSVerification]::($EnvPathName+"Verified")
        }

        if(Get-OSVerificationResults $EnvPathName $Results)
        {
            Write-Message -Type [MessageType]::Verbose -Key 'ConfirmPathVarIsValid' -Format {$PathVar}

            $Decision = Get-Confirmation -Message "$PathVar will be added to the 'PATH' environment variable."

            if($Decision -eq $True)
            {
                try
                {
                    Write-Message -Type [MessageType]::Verbose -Key 'PathVarSettingAttempt' -Format {$PathVar}

                    [System.Environment]::SetEnvironmentVariable("Path", $env:Path +";"+ $PathVar, [EnvironmentVariableTarget]::Machine)

                    Write-Message -Type ([MessageType]::Information) -Key 'ConfirmCreationOfEnvironmentVar' -Format {$PathVar}
                }
                catch
                {
                    Write-Message -Type ([MessageType]::Error) -Key 'UnableToChangeEnvironmentVar' -Action ([System.Management.Automation.ActionPreference]::Stop) -RecommendedAction 'SecurityRecommendment'
                }
            }
            else
            {
                Write-Message -Type ([MessageType]::Warning) -Key 'NewEnvironmentVarCancelled'
            }  
        }
        else 
        {
            Write-Message -Type ([MessageType]::Warning) -Key 'InvalidEnvironmentVarAttempt' -Action ([System.Management.Automation.ActionPreference]::Inquire) -Format {$PathVar}
        }
    }
    catch
    {
        Write-Message -Type ([MessageType]::Warning) -Key 'InvalidEnvironmentVarAttempt' -Action ([System.Management.Automation.ActionPreference]::Inquire) -Format {$PathVar}
    }
}


#internal function
function Edit-HistoryFile
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [array]$KeyfilePath
    )

    try
    {
        $PSHistoryFilePath = (Get-PSReadlineOption | Select-Object -ExpandProperty HistorySavePath)
        $PSHistoryTempFilePath = $PSHistoryFilePath+".tmp"

        Get-Content -Path $PSHistoryFilePath | ForEach-Object { $_ -replace "-KeyfilePath.*(?<!Mount\-TrueCrypt|mt)", "-KeyfilePath X:\XXXXX\XXXXX\XXXXX"} | Set-Content -Path $PSHistoryTempFilePath

        Copy-Item -Path $PSHistoryTempFilePath -Destination $PSHistoryFilePath -Force

        Remove-Item -Path $PSHistoryTempFilePath -Force
    }
    catch
    {
        Write-Message -Type ([MessageType]::Error) -Key 'UnableToRedact'
        Write-Message -Type ([MessageType]::Error) -Key 'Genaric' -Action ([System.Management.Automation.ActionPreference]::Inquire) -Format {$PSHistoryFilePath} 
    }
}

#internal function
function Get-PSTrueCryptContainer 
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    [System.String]$SubKeyName = Get-SubKeyPath -Name $Name

    if($SubKeyName -ne "")
    {
        $Settings = @{
            TrueCryptContainerPath  = Get-ItemProperty "HKCU:\SOFTWARE\PSTrueCrypt\$SubKeyName" | Select-Object -ExpandProperty Location
            PreferredMountDrive     = Get-ItemProperty "HKCU:\SOFTWARE\PSTrueCrypt\$SubKeyName" | Select-Object -ExpandProperty MountLetter
            Product                 = Get-ItemProperty "HKCU:\SOFTWARE\PSTrueCrypt\$SubKeyName" | Select-Object -ExpandProperty Product
            Timestamp               = (Get-ItemProperty "HKCU:\SOFTWARE\PSTrueCrypt\$SubKeyName" | Select-Object -ExpandProperty Timestamp) -eq 1
        }
    }
    else
    {
        Throw New-Object System.Management.Automation.ItemNotFoundException
    }

    $Settings
}


# internal function
function Get-SubKeyPath
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True)]
        [string]$Name
    )

    Push-Location
    Set-Location -Path HKCU:\SOFTWARE\PSTrueCrypt

    try 
    {
        Get-ChildItem . -Recurse | ForEach-Object {
            if ($Name -eq (Get-ItemProperty $_.PsPath).Name) 
            {
                $PSChildName = $_.PSChildName
            }
        }
    }
    catch 
    {
        # TODO: Need to throw specific error to calling method
        Write-Message -Type ([MessageType]::Error) -Key 'UnableToReadRegistry'
    }

    Pop-Location

    Write-Output $PSChildName
}


# internal function
function Get-TrueCryptMountParams 
{
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$TrueCryptContainerPath,

        [Parameter(Mandatory = $True, Position = 2)]
        [string]$PreferredMountDrive,

        [Parameter(Mandatory = $True, Position = 3)]
        [string]$Product,

        [Parameter(Mandatory = $False, Position = 4)]
        [array]$KeyfilePath,

        [Parameter(Mandatory = $False, Position = 5)]
        [bool]$Timestamp
    )

    $ParamsHash = @{
                        "/quit" = "";
                        "/volume" = "'$TrueCryptContainerPath'";
                        "/letter" = "'$PreferredMountDrive'";
                        "/auto" = "";
                        "/password" = "'{0}'";
                        "/explore" = "";
                    }

    $ParamsString = New-Object -TypeName "System.Text.StringBuilder";

    [void]$ParamsString.Insert(0, "& "+$Product+" ")

    if ($Timestamp) 
    {
        $ParamsHash.Add("/mountoption", "timestamp")
    }

    # add keyfile(s) if any to ParamsHash...
    if ($KeyfilePath.count -gt 0) 
    {
        $KeyfilePath | ForEach-Object { 
            $ParamsHash.Add("/keyfile", "'$_'")
        }
    }
    
    # populate ParamsString with ParamsHash data...
    $ParamsHash.GetEnumerator() | ForEach-Object {
        # if no value assigned to this TrueCrypt attribute, then just append attribute to ParamsString...
        if ($_.Value.Equals(""))
        {
            [void]$ParamsString.AppendFormat("{0}", $_.Key)
        }
        else
        {
            [void]$ParamsString.AppendFormat("{0} {1}", $_.Key, $_.Value)
        }

        [void]$ParamsString.Append(" ")
    }
    
    $ParamsString.ToString().TrimEnd(" ");
}


# internal function
function Get-TrueCryptDismountParams
{
    Param
    (
        [Parameter(Mandatory = $False)]
        [string]$Drive,

        [Parameter(Mandatory = $True)]
        [string]$Product
    )

    $ParamsHash = @{
                    "/quit" = "";
                    "/dismount" = $Drive
                }
    
    # Force dismount for all TrueCrypt volumes? ...
    if($Drive -eq "")
    {
        $ParamsHash.Add("/force", "")
    }

    $ParamsString = New-Object -TypeName "System.Text.StringBuilder";

    [void]$ParamsString.Insert(0, "& "+$Product+" ")

    $ParamsHash.GetEnumerator() | ForEach-Object {
        if ($_.Value.Equals("")) 
        {
            [void]$ParamsString.AppendFormat("{0}", $_.Key)
        }
        else
        {
            [void]$ParamsString.AppendFormat("{0} {1}", $_.Key, $_.Value)
        }

        [void]$ParamsString.Append(" ")
    }
    
    return $ParamsString.ToString().TrimEnd(" ");
}


# internal function
# ref: http://stackoverflow.com/a/24649481
function Get-Confirmation
{
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$Message
    )
    
    $Question = 'Are you sure you want to proceed?'

    $Choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
    $Choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList "&Yes"))
    $Choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList "&No"))

    $Decision = $Host.UI.PromptForChoice($Message, $Question, $Choices, 1)

    $Decision -eq 0
}


# internal function
function Invoke-DismountAll
{
    Param
    (
        [ValidateSet("TrueCrypt", "VeraCrypt")]
        [string]$Product
    )

    # construct arguments for Force dismount(s)...
    [string]$Expression = Get-TrueCryptDismountParams -Product $Product

    try
    {
        Invoke-Expression $Expression
        $HasXCryptDismountFailed = $False
    }
    catch 
    {
        $HasXCryptDismountFailed = $True
    }
    finally
    {
        if($HasXCryptDismountFailed -eq $False)
        {
            Write-Message -Type ([MessageType]::Information) -Key 'AllProductContainersDismounted' -Format {$Product}
        }
        else 
        {
            Write-Message -Type ([MessageType]::Error) -Key 'DismountException' -Format {$Product} 
        }
    }
}


# internal function
# ref: http://www.jonathanmedd.net/2014/01/testing-for-admin-privileges-in-powershell.html
function Test-IsAdmin 
{
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}


# internal function
function Get-OSVerificationResults
{
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$EnvPathName,

        [Parameter(Mandatory = $True, Position = 2)]
        [int]$Results,

        [ValidateSet("Found", "Valid", "Verified", "Success")]
        [string]$ResultStep = "Success"
    )

    try 
    {
        ([OSVerification]::($EnvPathName+$ResultStep) -band $Results)/[OSVerification]::($EnvPathName+$ResultStep) -eq $True
    }
    catch
    {
        $False
    }
}


function Write-Message
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [MessageType]$Type,

        [Parameter(Mandatory = $True, Position = 2)]
        [string]$Key,

        [Parameter(Mandatory = $False, Position = 3)]
        [System.Management.Automation.ActionPreference]$Action = [System.Management.Automation.ActionPreference]::Continue,

        [Parameter(Mandatory = $False)]
        [string[]]$Format,

        [Parameter(Mandatory = $False)]
        [string]$RecommendedAction
    )

    $Message
    $Recommendment

    switch ($Type) 
    {
        'Error' { 
            $Message = $ErrorRes.GetString($Key);
            $Recommendment = $ErrorRes.GetString($RecommendedAction)
            Break;
        }
        'Information' { $Message = $InformationRes.GetString($Key); Break }
        'Verbose' { $Message = $VerboseRes.GetString($Key); Break }
        'Warning' { $Message = $WarningRes.GetString($Key); Break }
    }

    if($Format)
    {
        $Message = $Message+" -f "+$Format
    }

    switch ($Type) 
    {
        'Error' {  Write-Error -Message $Message -ErrorId (Get-ErrorId $Key) -ErrorAction $Action -RecommendedAction $RecommendedAction ; Break }
        'Information' {  Write-Information -MessageData $Message -InformationAction $Action -RecommendedAction $RecommendedAction ; Break }
        'Verbose' {  Write-Verbose -Message $Message ; Break }
        'Warning' {  Write-Warning -Message $Message -WarningAction $Action ; Break }
    }
}


#http://jongurgul.com/blog/get-stringhash-get-filehash/ 
function Get-ErrorId
{
    Param
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [String]$Key,
        
        [Parameter(Mandatory = $False)]
        [String]$HashName = "MD5"
    )

    $StringBuilder = New-Object System.Text.StringBuilder

    [void]$StringBuilder.Append('E-')

    [System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Key)) | ForEach-Object { 
            [void]$StringBuilder.Append($_.ToString("x2")) 
    } 

    $StringBuilder.ToString(0,8).ToUpperInvariant()
}


function Initialize
{
    Add-Type -AssemblyName System.Windows.Forms 

    [int]$Results = 0;

    $Regex = "(\w+)\\?$"

    ($Env:Path).Split(';') | ForEach-Object {

        ($_ -match $Regex)
        $EnvPathName = $Matches[1]
        
        if(($EnvPathName -eq "TrueCrypt") -or ($EnvPathName -eq "VeraCrypt"))
        {
            $Results += [OSVerification]::($EnvPathName+"Found")

            try
            {
                Write-Message -Type [MessageType]::Verbose -Key 'EnvPathFoundAndWillBeTested' -Format {$EnvPathName}
                
                $IsValid = Test-Path $_ -IsValid
                
                if($IsValid -eq $True) {
                     $Results += [OSVerification]::($EnvPathName+"Valid")

                    $IsVerified = Test-Path $_
                    
                    if($IsVerified -eq $True) {
                        $Results += [OSVerification]::($EnvPathName+"Verified")
                    }
                }
            }
            # should be safe to swallow.  any discrepanceis will result in the Get-OSVerificationResults call...
            catch{ }

            if(Get-OSVerificationResults $EnvPathName $Results)
            {
                Write-Message -Type [MessageType]::Verbose -Key 'EnvPathSuccessfullyTested' -Format {$EnvPathName}
            }
            else
            {
                Write-Message -Type [MessageType]::Warning -Key 'EnvironmentVarPathFailed' -Format {$_}
                Write-Message -Type [MessageType]::Warning -Key 'EnvironmentVarRecommendation' -Format {$EnvPathName,$EnvPathName}
                Write-Message -Type [MessageType]::Warning -Key 'EnvironmentVarRecommendationExample' -Format {$EnvPathName}
                Write-Message -Type [MessageType]::Warning -Key 'EnvironmentVarRecommendation2'
            }
        }
    }
}

enum OSVerification {
    TrueCryptFound = 1
    VeraCryptFound = 2
                
    TrueCryptValid = 4
    VeraCryptValid = 8
     
    TrueCryptVerified = 16
    VeraCryptVerified = 32

    TrueCryptSuccess = 21
    VeraCryptSuccess = 42
}

enum MessageType {
    Error       = 1
    Information = 2
    Verbose     = 3
    Warning     = 4
}

Initialize

Set-Alias -Name mt -Value Mount-TrueCrypt
Set-Alias -Name dt -Value Dismount-TrueCrypt
Set-Alias -Name dtf -Value Dismount-TrueCryptForceAll

$ErrorRes = New-Object -TypeName 'System.Resources.ResXResourceSet' -ArgumentList $PSScriptRoot"\resx\Error.resx"
$InformationRes = New-Object -TypeName 'System.Resources.ResXResourceSet' -ArgumentList $PSScriptRoot"\resx\Information.resx"
$VerboseRes = New-Object -TypeName 'System.Resources.ResXResourceSet' -ArgumentList $PSScriptRoot"\resx\Verbose.resx"
$WarningRes = New-Object -TypeName 'System.Resources.ResXResourceSet' -ArgumentList $PSScriptRoot"\resx\Warning.resx"