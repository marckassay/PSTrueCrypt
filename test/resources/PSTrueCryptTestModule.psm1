$StorageLocation = @{
    Testing = 'HKCU:\SOFTWARE\PSTrueCrypt\Test'
}

function Start-InModuleScopeForPSTrueCrypt
{
    Param 
    (
        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [String]$ScriptFile = '.\resources\HKCU_Software_PSTrueCrypt_Test1.ps1'
    )

    Start-Transaction

    . $ScriptFile
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