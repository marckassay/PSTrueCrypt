function Start-InModuleScopeForPSTrueCrypt
{
    Start-Transaction

    . .\resources\HKCU_Software_PSTrueCrypt_Test1.ps1
}

function Complete-InModuleScopeForPSTrueCrypt
{
    Undo-Transaction
}