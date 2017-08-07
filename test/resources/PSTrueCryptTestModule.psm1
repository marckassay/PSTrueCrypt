$StorageLocation = @{
    Testing = 'HKCU:\SOFTWARE\PSTrueCrypt\Test'
}

function Start-InModuleScopeForPSTrueCrypt
{
    Param 
    (
        [switch]$NoLoad
    )

    Start-Transaction

    if($NoLoad -eq $False) {
        . .\resources\HKCU_Software_PSTrueCrypt_Test1.ps1
    } else {
        . .\resources\HKCU_Software_PSTrueCrypt_Test2.ps1
    }
}

function Complete-InModuleScopeForPSTrueCrypt
{
    Undo-Transaction
}

function Use-TestLocation 
{
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

    try {
        Set-Location -Path $Path -UseTransaction
        Invoke-Command -ScriptBlock $Script
    } catch {
        
    } finally {
        Pop-Location -UseTransaction
    }
}