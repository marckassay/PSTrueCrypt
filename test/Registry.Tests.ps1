Import-Module -Name .\StubModule

Describe "Test registry file..." {
    Start-Transaction

    New-Item "HKCU:\Software\PSTrueCrypt\Temp\a2d3671f-2062-4463-bc5f-0ed9a21c41fd" -Force -UseTransaction

    Set-ItemProperty "HKCU:\Software\PSTrueCrypt\Temp\a2d3671f-2062-4463-bc5f-0ed9a21c41fd" -Name 'Name' -Value 'MarcsTaxDocs' -UseTransaction
    
    $ContainerName = Get-ItemProperty "HKCU:\Software\PSTrueCrypt\Temp\a2d3671f-2062-4463-bc5f-0ed9a21c41fd" -UseTransaction | Select-Object -ExpandProperty 'Name'

    It "Be equal to Name" {
        $ContainerName | Should Be 'MarcsTaxDocs'
    }

    Set-ItemProperty "HKCU:\Software\PSTrueCrypt\Temp\a2d3671f-2062-4463-bc5f-0ed9a21c41fd" -Name 'Name' -Value 'AlicesTaxDocs' -UseTransaction

    $ContainerName = Get-ItemProperty "HKCU:\Software\PSTrueCrypt\Temp\a2d3671f-2062-4463-bc5f-0ed9a21c41fd" -UseTransaction | Select-Object -ExpandProperty 'Name'

    It "Be equal to Name" {
        $ContainerName | Should Be 'AlicesTaxDocs'
    }
    
    Undo-Transaction
}