Import-Module -Name .\StubModule
<#
Describe "Test Remove-PSTrueCryptContainer when called..." {
    
    Context "with legit name..." {

        InModuleScope PSTrueCrypt {

            Mock Get-SubKeyPath {return 'e03e195e-c069-4c6b-9d35-6b61cdf40aad' }

            Mock Remove-SubKey{}

            It "Should of called Remove-SubKey with SubKeyName..." {
                Assert-MockCalled Remove-SubKey -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $SubKey -like '*e03e195e-c069-4c6b-9d35-6b61cdf40aad'
                }
            }
        }
    }
}

#>