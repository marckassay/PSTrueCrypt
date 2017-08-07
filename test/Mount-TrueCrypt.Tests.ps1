Import-Module $PSScriptRoot\resources\PSTrueCryptTestModule.psm1

Describe "Test Mount-TrueCrypt when called..." {
    Context "with no KeyfilePath..." {
        InModuleScope PSTrueCrypt {
            $SUT = $True

            Mock Start-CimLogicalDiskWatch {}
            Mock Test-IsAdmin { return $True } -Verifiable
            Mock Read-Host { return  ConvertTo-SecureString "123abc" -AsPlainText -Force } -Verifiable
            Mock Set-ItemProperty {} -Verifiable
            Mock Invoke-Expression {}
            Mock Edit-HistoryFile {}

            Start-InModuleScopeForPSTrueCrypt

            Mount-TrueCrypt -Name 'BobsTaxDocs'

            It "Should of called internal functions..." {
                Assert-VerifiableMocks
            }
            
            It "Should of called Start-CimLogicalDiskWatch with 'KeyId' and 'InstanceType' value..." {
                Assert-MockCalled Start-CimLogicalDiskWatch -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    ($KeyId -eq '00000000-0000-0000-0000-00000002') -and ($InstanceType -eq 'Creation')
                }
            }

            It "Should of called Invoke-Expression with the value being used in this comparison operator..." {
                Assert-MockCalled Invoke-Expression -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $Command -eq "& TrueCrypt /explore /password '123abc' /volume 'C:\Users\Bob\Documents\BobsContainer' /quit /auto /letter 'T'"
                }
            }

            Complete-InModuleScopeForPSTrueCrypt
        }
    }
    
    Context "with KeyfilePath..." {
        InModuleScope PSTrueCrypt {
            $SUT = $True

            Mock Start-CimLogicalDiskWatch {}
            Mock Test-IsAdmin { return $True } -Verifiable
            Mock Read-Host { return  ConvertTo-SecureString "123abc" -AsPlainText -Force } -Verifiable
            Mock Set-ItemProperty {} -Verifiable
            Mock Invoke-Expression {}
            Mock Edit-HistoryFile {} -Verifiable

            Start-InModuleScopeForPSTrueCrypt

            Mount-TrueCrypt -Name 'BobsTaxDocs' -KeyfilePath "C:\Users\Bob\Music\ABC.mp3"

            It "Should of called internal functions..." {
                Assert-VerifiableMocks
            }

            It "Should of called Start-CimLogicalDiskWatch with 'KeyId' and 'InstanceType' value..." {
                Assert-MockCalled Start-CimLogicalDiskWatch -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    ($KeyId -eq '00000000-0000-0000-0000-00000002') -and ($InstanceType -eq 'Creation')
                }
            }

            It "Should of called Invoke-Expression with the value being used in this comparison operator..." {
                Assert-MockCalled Invoke-Expression -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $Command -eq "& TrueCrypt /keyfile 'C:\Users\Bob\Music\ABC.mp3' /explore /password '123abc' /volume 'C:\Users\Bob\Documents\BobsContainer' /quit /auto /letter 'T'"
                }
            }

            Complete-InModuleScopeForPSTrueCrypt
        }
    }
    
    Context "with SecureString..." {
        InModuleScope PSTrueCrypt {
            $SUT = $True

            Mock Start-CimLogicalDiskWatch {}
            Mock Invoke-Expression {}
            Mock Edit-HistoryFile {}

            Start-InModuleScopeForPSTrueCrypt

            $SecureString = ConvertTo-SecureString '123abc' -AsPlainText -Force

            Mount-TrueCrypt -Name 'BobsTaxDocs' -KeyfilePath "C:\Users\Bob\Music\ABC.mp3" -Password $SecureString

            It "Should of called internal functions..." {
                Assert-VerifiableMocks
            }

            It "Should of called Start-CimLogicalDiskWatch with 'KeyId' and 'InstanceType' value..." {
                Assert-MockCalled Start-CimLogicalDiskWatch -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    ($KeyId -eq '00000000-0000-0000-0000-00000002') -and ($InstanceType -eq 'Creation')
                }
            }

            It "Should of called Invoke-Expression with the value being used in this comparison operator..." {
                Assert-MockCalled Invoke-Expression -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $Command -eq "& TrueCrypt /keyfile 'C:\Users\Bob\Music\ABC.mp3' /explore /password '123abc' /volume 'C:\Users\Bob\Documents\BobsContainer' /quit /auto /letter 'T'"
                }
            }

            Complete-InModuleScopeForPSTrueCrypt
        }
    }
}