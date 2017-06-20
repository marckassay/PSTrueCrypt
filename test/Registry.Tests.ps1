Import-Module -Name .\StubModule

Describe "Test registry file..." {

    Start-Transaction
    
    . .\resources\HKCU_Software_PSTrueCrypt_1.ps1

    $ContainerName = Get-ItemProperty "HKCU:\Software\PSTrueCrypt\00000000-0000-0000-0000-00000001" -UseTransaction | Select-Object -ExpandProperty 'Name'

    It "Be equal to Name" {
        $ContainerName | Should Be 'MarcsTaxDocs'
    }

    Set-ItemProperty "HKCU:\Software\PSTrueCrypt\00000000-0000-0000-0000-00000001" -Name 'Name' -Value 'AlicesTaxDocs' -UseTransaction

    $ContainerName = Get-ItemProperty "HKCU:\Software\PSTrueCrypt\00000000-0000-0000-0000-00000001" -UseTransaction | Select-Object -ExpandProperty 'Name'

    It "Be equal to Name" {
        $ContainerName | Should Be 'AlicesTaxDocs'
    }

    $MountLetter = Get-ItemProperty "HKCU:\Software\PSTrueCrypt\00000000-0000-0000-0000-00000001" -UseTransaction | Select-Object -ExpandProperty 'MountLetter'

    It "Be equal to MountLetter" {
        $MountLetter | Should Be 'Y'
    }
    
    Undo-Transaction
}