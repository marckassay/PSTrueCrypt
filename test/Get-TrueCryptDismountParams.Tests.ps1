Describe "Get-TrueCryptDismountParams when called..." {
    It "Should return expected string" {
        Get-TrueCryptDismountParams -Drive 'H' -Product 'TrueCrypt' | Should BeExactly '& TrueCrypt /dismount H /quit' 
    }
    It "Should return expected string" {
        Get-TrueCryptDismountParams -Drive 'H' -Product 'VeraCrypt' | Should BeExactly '& VeraCrypt /dismount H /quit' 
    }
}