Import-Module $PSScriptRoot\..\src\Storage\PSTrueCrypt.Storage.psm1
Import-Module $PSScriptRoot\..\src\Writer\PSTrueCrypt.Writer.psm1
Import-Module $PSScriptRoot\resources\PSTrueCryptTestModule.psm1

Describe "Test Show-PSTrueCryptContainer when called..." {
    Context "while 4 containers are in registry" {
        InModuleScope PSTrueCrypt {
            $SUT = $True

            Start-InModuleScopeForPSTrueCrypt 

            Mock Restart-LogicalDiskCheck {} -Verifiable
            Mock Format-Table {} -Verifiable -ParameterFilter { ($InputObject.Count -eq 4) -and `
                (($InputObject.Item(0)).Name -eq 'AlicesTaxDocs') -and `
                (($InputObject.Item(1)).Name -eq 'BobsTaxDocs') -and `
                (($InputObject.Item(2)).Name -eq 'Krytos') -and `
                (($InputObject.Item(3)).Name -eq 'MarcsTaxDocs')
            }

            Show-PSTrueCryptContainers

            It "Should of called internal functions..." {
                Assert-VerifiableMocks
            }

            Complete-InModuleScopeForPSTrueCrypt
        }
    }
   
    Context "while no containers are in registry" {
        InModuleScope PSTrueCrypt {
            $SUT = $True

            Start-InModuleScopeForPSTrueCrypt -NoScriptFile

            Mock Out-Information {}

            Show-PSTrueCryptContainers
            
            It "Should of called Out-Information with 'NoPSTrueCryptContainerFound' value..." {
                Assert-MockCalled Out-Information -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $Key -eq 'NoPSTrueCryptContainerFound'
                }
            }

            Complete-InModuleScopeForPSTrueCrypt
        }
    }
}