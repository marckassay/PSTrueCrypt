$StorageLocation = @{
    Testing = 'HKCU:\SOFTWARE\PSTrueCrypt\Test'
}

function Start-InModuleScopeForPSTrueCrypt
{
    Param 
    (
        [Parameter(Mandatory = $False, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [String]$ScriptFile = "$PSScriptRoot\HKCU_Software_PSTrueCrypt_Test1.ps1",

        [switch]$NoScriptFile
    )
    
    Start-Transaction

    if($NoScriptFile -eq $False) {
        . $ScriptFile
    } else {
        New-Item -Path $StorageLocation.Testing -Force -UseTransaction
    }
}

function Complete-InModuleScopeForPSTrueCrypt
{
    Undo-Transaction
}

function Use-TestLocation 
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$True, Position=1)]
        [ValidateNotNullOrEmpty()]
        [ScriptBlock]
        $Script
    )

    Use-Location -Path $StorageLocation.Testing -Script $Script
}

function Use-Location 
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$True, Position=1)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path,

        [Parameter(Mandatory=$True, Position=2)]
        [ScriptBlock]
        $Script
    )

    Push-Location
    
    Set-Location -Path $Path -UseTransaction

    Invoke-Command -ScriptBlock $Script

    Pop-Location
}

Export-ModuleMember -Function Start-InModuleScopeForPSTrueCrypt
Export-ModuleMember -Function Complete-InModuleScopeForPSTrueCrypt
Export-ModuleMember -Function Use-TestLocation 

Export-ModuleMember -Variable StorageLocation