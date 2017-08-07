Import-Module $PSScriptRoot\..\src\Storage\PSTrueCrypt.Storage.psm1
Import-Module $PSScriptRoot\..\src\Writer\PSTrueCrypt.Writer.psm1
Import-Module $PSScriptRoot\resources\PSTrueCryptTestModule.psm1

Describe "Test New-PSTrueCryptContainer when called..." {
    Context "with valid entries without Timestamp" {
        InModuleScope PSTrueCrypt {
            $SUT = $True

            Start-InModuleScopeForPSTrueCrypt -ScriptFile '.\resources\HKCU_Software_PSTrueCrypt_Test3.ps1'
            
            Mock Get-Confirmation { return $True } -Verifiable

            Mock Out-Information{}

            Mock New-Guid { return '00000000-0000-0000-0000-00000003' }

            Mock New-Container {} 

            New-PSTrueCryptContainer -Name 'AlicesTaxDocs' -Location "C:\Users\Alice\Documents\AlicesContainer" -MountLetter 'V' -Product 'VeraCrypt'

            It "Should of called internal functions..." {
                Assert-VerifiableMocks
            }

            It "Should of called New-Container setting the Name property of this subkey..." {
                Assert-MockCalled New-Container -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $Name -eq "AlicesTaxDocs"
                }
            }
            
            It "Should of called New-Container setting the Location property of this subkey..." {
                Assert-MockCalled New-Container -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $Location -eq "C:\Users\Alice\Documents\AlicesContainer"
                }
            }

            It "Should of called New-Container setting the MountLetter property of this subkey..." {
                Assert-MockCalled New-Container -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $MountLetter -eq "V"
                }
            }

            It "Should of called New-Container setting the Product property of this subkey..." {
                Assert-MockCalled New-Container -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $Product -eq "VeraCrypt"
                }
            }

            It "Should of called New-Container setting the Timestamp property of this subkey..." {
                Assert-MockCalled New-Container -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $Timestamp -eq $False
                }
            }
            
            It "Should of called Out-Information with 'NewContainerOperationSucceeded' value..." {
                Assert-MockCalled Out-Information -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    ($Key -eq 'NewContainerOperationSucceeded') -and ($Format -eq "AlicesTaxDocs")
                }
            } 

            Complete-InModuleScopeForPSTrueCrypt 
        }
    }

    Context "with valid entries with Timestamp" {

        InModuleScope PSTrueCrypt {
            $SUT = $True

            Start-InModuleScopeForPSTrueCrypt -ScriptFile '.\resources\HKCU_Software_PSTrueCrypt_Test3.ps1'
            
            Mock Get-Confirmation { return $True } -Verifiable

            Mock Out-Information{}

            Mock New-Guid { return '00000000-0000-0000-0000-00000003' }

            Mock New-Container {} 

            New-PSTrueCryptContainer -Name 'AlicesTaxDocs' -Location "C:\Users\Alice\Documents\AlicesContainer" -MountLetter 'V' -Product 'VeraCrypt' -Timestamp

            It "Should of called internal functions..." {
                Assert-VerifiableMocks
            }

            It "Should of called New-Container setting the Name property of this subkey..." {
                Assert-MockCalled New-Container -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $Name -eq "AlicesTaxDocs"
                }
            }
            
            It "Should of called New-Container setting the Location property of this subkey..." {
                Assert-MockCalled New-Container -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $Location -eq "C:\Users\Alice\Documents\AlicesContainer"
                }
            }

            It "Should of called New-Container setting the MountLetter property of this subkey..." {
                Assert-MockCalled New-Container -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $MountLetter -eq "V"
                }
            }

            It "Should of called New-Container setting the Product property of this subkey..." {
                Assert-MockCalled New-Container -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $Product -eq "VeraCrypt"
                }
            }

            It "Should of called New-Container setting the Timestamp property of this subkey..." {
                Assert-MockCalled New-Container -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $Timestamp -eq $True
                }
            }
            
            It "Should of called Out-Information with 'NewContainerOperationSucceeded' value..." {
                Assert-MockCalled Out-Information -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    ($Key -eq 'NewContainerOperationSucceeded') -and ($Format -eq "AlicesTaxDocs")
                }
            } 

            Complete-InModuleScopeForPSTrueCrypt 
        }
    }

    Context "with invalid and valid MountLetter values" {

        InModuleScope PSTrueCrypt {

            It "Should of expected an exception from MountLetter attribute..." {
                {New-PSTrueCryptContainer -Name 'AlicesTaxDocs' -Location "C:\Users\Alice\Documents\AlicesContainer" -MountLetter 'VV' -Product 'VeraCrypt' -Timestamp} | Should Throw "Cannot validate argument on parameter 'MountLetter'"
            }
            It "Should of expected an exception from MountLetter attribute..." {
                {New-PSTrueCryptContainer -Name 'AlicesTaxDocs' -Location "C:\Users\Alice\Documents\AlicesContainer" -MountLetter 'V ' -Product 'VeraCrypt' -Timestamp} | Should Throw "Cannot validate argument on parameter 'MountLetter'"
            }

            It "Should of not expected an exception from MountLetter attribute..." {
                {New-PSTrueCryptContainer -Name 'AlicesTaxDocs' -Location "C:\Users\Alice\Documents\AlicesContainer" -MountLetter 'V' -Product 'VeraCrypt' -Timestamp} | Should Not Throw "Cannot validate argument on parameter 'MountLetter'"
            }
        }
    }
}