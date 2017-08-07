Import-Module $PSScriptRoot\..\src\PSTrueCrypt.CommandLine.psm1

Describe "Get-TrueCryptDismountParams when called..." {
    Context "with valid data" {
        InModuleScope PSTrueCrypt.CommandLine {
            It "Should return expected string" {
                Get-TrueCryptDismountParams -Drive 'T' -Product 'TrueCrypt' | Should BeExactly '& TrueCrypt /dismount T /quit' 
            }
            
            It "Should return expected string" {
                Get-TrueCryptDismountParams -Drive 'V' -Product 'VeraCrypt' | Should BeExactly '& VeraCrypt /dismount V /quit' 
            }
        }
    }
}