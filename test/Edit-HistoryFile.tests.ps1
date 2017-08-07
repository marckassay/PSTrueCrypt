#Import-Module -Name .\StubModule
# TODO: for this test to to work, source code will need to be modified for 2 reasons:
# - the redacted value 'X:\XXXXX...' cant seem to be escaped 
# - And the pipeline in the body of this function will need to be broke apart 
#   so that $TestDrive can get in the url

<# 
Describe "Test Edit-HistoryFile when called..." {

    #Copy-Item "$PSScriptRoot\resources\ConsoleHost_history.1.txt" -Destination $TestDrive
    
    Context "With full function name..." {

        InModuleScope PSTrueCrypt {
            Mock Select-Object { return "$TestDrive\ConsoleHost_history.1.txt" }

            Edit-HistoryFile

            It "Should of called internal functions..." {
                Assert-VerifiableMocks
            }

            It "Should of redacted uri to keyfilepath..." {
               "$TestDrive\ConsoleHost_history.1.txt" | Should ContainExactly "Mount-TrueCrypt -Name AlicesContainer -KeyfilePath X:\XXXXX\XXXXX\XXXXX" 
            }
        }
    }
}
#>