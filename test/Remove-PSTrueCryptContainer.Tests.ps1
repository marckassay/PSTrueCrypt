Import-Module $PSScriptRoot\..\src\Storage\PSTrueCrypt.Storage.psm1
Import-Module $PSScriptRoot\..\src\Writer\PSTrueCrypt.Writer.psm1
Import-Module $PSScriptRoot\resources\PSTrueCryptTestModule.psm1

Describe "Remove-PSTrueCryptContainer when called..." {
    
    Context "and user accepted removal..." {

        InModuleScope PSTrueCrypt {
            $SUT = $True

            Start-InModuleScopeForPSTrueCrypt 

            Mock Get-Confirmation { return $True } 

            Mock Out-Information {}

            Join-Path $StorageLocation.Testing -ChildPath '00000000-0000-0000-0000-00000003' -UseTransaction -OutVariable P
            Get-ItemProperty $P -Name Name -UseTransaction -OutVariable PriorToFixtureCallName 

            Remove-PSTrueCryptContainer AlicesTaxDocs

            It "Should return its object prior to removal..." {
                 $PriorToFixtureCallName.Name | Should BeExactly 'AlicesTaxDocs'
            }

            It "Should of called Out-Information with 'ContainerSettingsDeleted' value..." {
                Assert-MockCalled Out-Information -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $Key -eq 'ContainerSettingsDeleted'
                }
            }

            Complete-InModuleScopeForPSTrueCrypt
        }
    }
    
    Context "and user cancels removal..." {

        InModuleScope PSTrueCrypt {
            $SUT = $True

            Start-InModuleScopeForPSTrueCrypt 

            Mock Get-Confirmation { return $False } 

            Mock Out-Information {}

            Join-Path $StorageLocation.Testing -ChildPath '00000000-0000-0000-0000-00000003' -UseTransaction -OutVariable P
            Get-ItemProperty $P -Name Name -UseTransaction -OutVariable PriorToFixtureCallName 

            Remove-PSTrueCryptContainer AlicesTaxDocs

            It "Should return its object prior to removal..." {
                 $PriorToFixtureCallName.Name | Should BeExactly 'AlicesTaxDocs'
            }

            It "Should of called Out-Information with 'RemoveContainerOperationCancelled' value..." {
                Assert-MockCalled Out-Information -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $Key -eq 'RemoveContainerOperationCancelled'
                }
            }

            Complete-InModuleScopeForPSTrueCrypt
        }
    }
}