Import-Module -Name .\StubModule

Describe "Test New-PSTrueCryptContainer when called..." {

    $OutTestPath = Split-Path -Path $PSScriptRoot -Parent | Join-Path -ChildPath "out/test/resources"
    
    Context "with valid entries without Timestamp" {

        InModuleScope PSTrueCrypt {

            Mock Get-Confirmation { return $True } -Verifiable

            Mock New-Guid { return 'e03e195e-c069-4c6b-9d35-6b61cdf40aad' }

            Mock Out-Information{} -Verifiable

            Mock New-ItemProperty {}

            New-PSTrueCryptContainer -Name 'AlicesPSTrueCryptContainer' -Location "$OutTestPath/AlicesTrueCryptContainerFile" -MountLetter 'T' -Product 'TrueCrypt'

            It "Should of called internal functions..." {
                Assert-VerifiableMocks
            }

            It "Should of called New-ItemProperty by setting the Path and Name property of this subkey..." {
                Assert-MockCalled New-ItemProperty -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    ($Path -like '*e03e195e-c069-4c6b-9d35-6b61cdf40aad') -and ($Value -eq 'AlicesPSTrueCryptContainer')
                }
            }

            It "Should of called New-ItemProperty setting the Location property of this subkey..." {
                Assert-MockCalled New-ItemProperty -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    ($Path -like '*e03e195e-c069-4c6b-9d35-6b61cdf40aad') -and ($Value -eq "$OutTestPath/AlicesTrueCryptContainerFile")
                }
            }

            It "Should of called New-ItemProperty setting the MountLetter property of this subkey..." {
                Assert-MockCalled New-ItemProperty -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    ($Path -like '*e03e195e-c069-4c6b-9d35-6b61cdf40aad') -and ($Value -eq "T")
                }
            }

            It "Should of called New-ItemProperty setting the Product property of this subkey..." {
                Assert-MockCalled New-ItemProperty -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    ($Path -like '*e03e195e-c069-4c6b-9d35-6b61cdf40aad') -and ($Value -eq "TrueCrypt")
                }
            }

            It "Should of called New-ItemProperty setting the Timestamp property of this subkey..." {
                Assert-MockCalled New-ItemProperty -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    ($Path -like '*e03e195e-c069-4c6b-9d35-6b61cdf40aad') -and ($Value -eq $False.GetHashCode())
                }
            }
        }
    }

    Context "with valid entries with Timestamp" {

        InModuleScope PSTrueCrypt {

            Mock Get-Confirmation { return $True } -Verifiable

            Mock New-Guid { return 'e03e195e-c069-4c6b-9d35-6b61cdf40aad' }

            Mock Out-Information{} -Verifiable

            Mock New-ItemProperty {}

            New-PSTrueCryptContainer -Name 'AlicesPSTrueCryptContainer' -Location "$OutTestPath/AlicesTrueCryptContainerFile" -MountLetter 'T' -Product 'TrueCrypt' -Timestamp

            It "Should of called internal functions..." {
                Assert-VerifiableMocks
            }

            It "Should of called New-ItemProperty by setting the Path and Name property of this subkey..." {
                Assert-MockCalled New-ItemProperty -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    ($Path -like '*e03e195e-c069-4c6b-9d35-6b61cdf40aad') -and ($Value -eq 'AlicesPSTrueCryptContainer')
                }
            }

            It "Should of called New-ItemProperty setting the Location property of this subkey..." {
                Assert-MockCalled New-ItemProperty -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    ($Path -like '*e03e195e-c069-4c6b-9d35-6b61cdf40aad') -and ($Value -eq "$OutTestPath/AlicesTrueCryptContainerFile")
                }
            }

            It "Should of called New-ItemProperty setting the MountLetter property of this subkey..." {
                Assert-MockCalled New-ItemProperty -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    ($Path -like '*e03e195e-c069-4c6b-9d35-6b61cdf40aad') -and ($Value -eq "T")
                }
            }

            It "Should of called New-ItemProperty setting the Product property of this subkey..." {
                Assert-MockCalled New-ItemProperty -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    ($Path -like '*e03e195e-c069-4c6b-9d35-6b61cdf40aad') -and ($Value -eq "TrueCrypt")
                }
            }

            It "Should of called New-ItemProperty setting the Timestamp property of this subkey..." {
                Assert-MockCalled New-ItemProperty -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    ($Path -like '*e03e195e-c069-4c6b-9d35-6b61cdf40aad') -and ($Value -eq $True.GetHashCode())
                }
            }
        }
    }
}