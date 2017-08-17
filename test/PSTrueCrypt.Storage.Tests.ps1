Import-Module $PSScriptRoot\..\src\Storage\PSTrueCrypt.Storage.psm1
Import-Module $PSScriptRoot\..\src\Writer\PSTrueCrypt.Writer.psm1
Import-Module $PSScriptRoot\resources\PSTrueCryptTestModule.psm1

Describe "Test PSTrueCrypt.Storage when called..." {
    Context "with valid data" {
        InModuleScope PSTrueCrypt.Storage {
            Start-InModuleScopeForPSTrueCrypt 

            Use-TestLocation {
                Get-RegistrySubKeys | Get-SubKeyByPropertyValue -Name 'AlicesTaxDocs' | Read-Container
            } -OutVariable FixtureResults
            
            It "Should return its Settings object with expected Location value..." {
                $FixtureResults.Location | Should BeExactly 'C:\Users\Alice\Documents\AlicesContainer'
            }

            It "Should return its Settings object with expected MountLetter value..." {
                $FixtureResults.MountLetter | Should BeExactly 'V'
            }

            It "Should return its Settings object with expected Product value..." {
                $FixtureResults.Product | Should BeExactly 'VeraCrypt'
            }

            It "Should return its Settings object with expected Timestamp value..." {
                $FixtureResults.Timestamp | Should BeExactly 1
            }

            Complete-InModuleScopeForPSTrueCrypt
        }
    }

    Context "with invalid data"  {
        InModuleScope PSTrueCrypt.Storage {
            Start-InModuleScopeForPSTrueCrypt -NoScriptFile 

            try {
                Use-TestLocation {
                    Get-RegistrySubKeys
                } -ErrorAction Ignore -ErrorVariable RegistrySubKeysError
            } catch [System.NullReferenceException] {
                $ErrorType = $RegistrySubKeysError.Item(0).Exception.toString()

                Set-Location -Path $PSScriptRoot
            }
            
            It "Should of thrown 'NullReferenceException' exception..." {
                $ErrorType |  Should Match 'System.NullReferenceException'
            }

            Complete-InModuleScopeForPSTrueCrypt
        } 
    }
}