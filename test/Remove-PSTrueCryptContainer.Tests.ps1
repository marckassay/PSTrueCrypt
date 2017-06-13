Import-Module -Name .\StubModule

Describe "Remove-PSTrueCryptContainer when called..." {
    
    Context "with valid name..." {

        InModuleScope PSTrueCrypt {

            Mock Get-SubKeyPath { return 'e03e195e-c069-4c6b-9d35-6b61cdf40aad' }

            Mock Out-Information{}

            Mock Remove-HKCUSubKey{}

            Remove-PSTrueCryptContainer AlicesTaxDocs

            It "Should of called Remove-HKCUSubKey with correct FullPath value..." {
                Assert-MockCalled Remove-HKCUSubKey -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $FullPath -eq 'SOFTWARE\PSTrueCrypt\e03e195e-c069-4c6b-9d35-6b61cdf40aad'
                }
            }

            It "Should of called Out-Information with 'ContainerSettingsDeleted' value..." {
                Assert-MockCalled Out-Information -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $Key -eq 'ContainerSettingsDeleted'
                }
            }
        }
    }
    
    Context "with invalid name..." {

        InModuleScope PSTrueCrypt {

            Mock Get-SubKeyPath { return $null }

            Mock Out-Error{}

            Mock Remove-HKCUSubKey{}

            Remove-PSTrueCryptContainer AlicesDaxTocs 

            It "Should of called Out-Error with 'UnableToFindPSTrueCryptContainer' value..." {
                Assert-MockCalled Out-Error -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $Key -eq 'UnableToFindPSTrueCryptContainer'
                }
            }
        }
    }
}