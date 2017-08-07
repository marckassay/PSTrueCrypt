Import-Module $PSScriptRoot\StubModule.psm1

Describe "Test Dismount-TrueCrypt when called..." {

    Context "with valid Name" {
        InModuleScope PSTrueCrypt {
            Mock Start-CimLogicalDiskWatch {}

            Mock Invoke-Expression {}

            $SUT = $True
            Start-Transaction
            . .\resources\HKCU_Software_PSTrueCrypt_Test1.ps1
           # Set-Location HKCU:\Software\PSTrueCrypt\Test -UseTransaction

            Dismount-TrueCrypt -Name 'AlicesTaxDocs'

            It "Should of called Start-CimLogicalDiskWatch with 'KeyId' and 'InstanceType' value..." {
                Assert-MockCalled Start-CimLogicalDiskWatch -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    ($KeyId -eq '00000000-0000-0000-0000-00000003') -and ($InstanceType -eq 'Deletion')
                }
            }

            It "Should of called Invoke-Expression with the value being used in this comparison operator..." {
                Assert-MockCalled Invoke-Expression -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $Command -eq "& VeraCrypt /dismount V /quit"
                }
            }

            Undo-Transaction
            $SUT = $False
        }
    }
}