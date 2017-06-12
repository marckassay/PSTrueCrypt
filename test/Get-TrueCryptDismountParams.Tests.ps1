Describe "Get-TrueCryptDismountParams when called..." {

    It "Should of correct string returned" {
        Get-TrueCryptDismountParams -Drive 'H' -Product 'TrueCrypt' | Should BeExactly '& TrueCrypt /dismount H /quit' 
    }
    It "Should of correct string returned" {
        Get-TrueCryptDismountParams -Drive 'H' -Product 'VeraCrypt' | Should BeExactly '& VeraCrypt /dismount H /quit' 
    }
}