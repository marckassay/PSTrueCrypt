Import-Module -Name .\StubModule

Describe "Test Get-PSTrueCryptContainer when called..." {
    
    Context "with valid data" {

        InModuleScope PSTrueCrypt {

            $SubKeyPath = "HKCU:\SOFTWARE\PSTrueCrypt\e03e195e-c069-4c6b-9d35-6b61cdf40aad"

            $ExpectedResults = [PSCustomObject]@{
                Name            = 'AlicesContainer'
                Location        = 'D:\Google Drive\Documents\veracrypt'
                MountLetter     = 'H'
                Product         = 'VeraCrypt'
                Timestamp       = 1
                PSPath          = 'noop'
                PSParentPath    = 'noop'
                PSChildName     = 'e03e195e-c069-4c6b-9d35-6b61cdf40aad'
                PSDrive         = 'HKCU'
                PSProvider      = 'Microsoft.PowerShell.Core\Registry'
            }

            Mock Get-SubKeyPath { return $SubKeyPath } -Verifiable

            Mock Get-ItemProperty { return $ExpectedResults }

            $FixtureResults = Get-PSTrueCryptContainer -Name 'AlicesContainer'

            It "Should of called internal functions..." {
                Assert-VerifiableMocks
            }

            It "Should return its Settings object with expected Location value..." {
                $FixtureResults.TrueCryptContainerPath | Should BeExactly 'D:\Google Drive\Documents\veracrypt'
            }

            It "Should return its Settings object with expected MountLetter value..." {
                $FixtureResults.PreferredMountDrive | Should BeExactly 'H'
            }

            It "Should return its Settings object with expected Product value..." {
                $FixtureResults.Product | Should BeExactly 'VeraCrypt'
            }

            It "Should return its Settings object with expected Timestamp value..." {
                $FixtureResults.Timestamp | Should BeExactly 1
            }
        }
    }
    
    Context "with invalid data" {

        InModuleScope PSTrueCrypt {

            Mock Get-SubKeyPath { return "" } -Verifiable

            Mock Out-Error {}

            Get-PSTrueCryptContainer -Name 'AlicesContainer'

            It "Should of called internal functions..." {
                Assert-VerifiableMocks
            }

            It "Should of called Out-Error with 'UnableToFindPSTrueCryptContainer' value..." {
                Assert-MockCalled Out-Error -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $Key -eq 'UnableToFindPSTrueCryptContainer'
                }
            }
        }
    }
}