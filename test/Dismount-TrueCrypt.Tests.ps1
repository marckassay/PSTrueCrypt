Import-Module -Name .\StubModule

Describe "Test Dismount-TrueCrypt when called..." {

    Context "with valid Name" {
        InModuleScope PSTrueCrypt {
            Mock Get-PSTrueCryptContainer { 
            @{
                TrueCryptContainerPath = "C:\Users\Alice\Documents\AlicesContainer"
                PreferredMountDrive = "V";
                Product = "VeraCrypt";
                Timestamp = 0x00000000
            }} -Verifiable

            Mock Invoke-Expression {}
            
            Dismount-TrueCrypt -Name 'AliceTaxDocs'

            It "Should of called Invoke-Expression with the value being used in this comparison operator..." {
                Assert-MockCalled Invoke-Expression -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $Command -eq "& VeraCrypt /dismount V /quit"
                }
            }
        }
    }
}