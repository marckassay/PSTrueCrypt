Describe "Get-TrueCryptDismountParams when called..." {
    InModuleScope PSTrueCrypt {
        It "Should return expected string" {
            Get-TrueCryptDismountParams -Drive 'T' -Product 'TrueCrypt' | Should BeExactly '& TrueCrypt /dismount T /quit' 
        }
        It "Should return expected string" {
            Get-TrueCryptDismountParams -Drive 'V' -Product 'VeraCrypt' | Should BeExactly '& VeraCrypt /dismount V /quit' 
        }
    }
}