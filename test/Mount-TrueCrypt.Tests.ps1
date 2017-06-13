Import-Module -Name .\StubModule

Describe "Test Mount-TrueCrypt when called..." {
    
    BeforeEach {
        #$OutTestPath = Split-Path -Path $PSScriptRoot -Parent | Join-Path -ChildPath "out/test/resources"
        
        #Remove-Item -Path $OutTestPath -Recurse -ErrorAction Silently 
        
        #Copy-Item "$PSScriptRoot/resources" -Destination $OutTestPath -Recurse
    }

    AfterEach {
        #Split-Path -Path $PSScriptRoot -Parent | Join-Path -ChildPath "out" | Remove-Item -Recurse
    }
    
    Context "with no KeyfilePath..." {
        InModuleScope PSTrueCrypt {
            Mock Get-PSTrueCryptContainer { 
            @{
                TrueCryptContainerPath = "C:\Users\Bob\Documents\BobsContainer"
                PreferredMountDrive = "T";
                Product = "TrueCrypt";
                Timestamp = 0x00000000
            }} -Verifiable

            Mock Test-IsAdmin { return $True } -Verifiable

            Mock Read-Host { return  ConvertTo-SecureString "123abc" -AsPlainText -Force } -Verifiable

            Mock Set-ItemProperty {} -Verifiable

            Mock Invoke-Expression {}
            
            Mock Edit-HistoryFile {}

            Mount-TrueCrypt -Name 'BobsTaxDocs'

            It "Should of called internal functions..." {
                Assert-VerifiableMocks
            }

            It "Should of called Invoke-Expression with the value being used in this comparison operator..." {
                Assert-MockCalled Invoke-Expression -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $Command -eq "& TrueCrypt /explore /password '123abc' /volume 'C:\Users\Bob\Documents\BobsContainer' /quit /auto /letter 'T'"
                }
            }
        }
    }
    
    Context "with KeyfilePath..." {
        InModuleScope PSTrueCrypt {
            Mock Get-PSTrueCryptContainer { 
            @{
                TrueCryptContainerPath = "C:\Users\Bob\Documents\BobsContainer"
                PreferredMountDrive = "T";
                Product = "TrueCrypt";
                Timestamp = 0x00000000
            }} -Verifiable

            Mock Test-IsAdmin { return $True } -Verifiable

            Mock Read-Host { return  ConvertTo-SecureString "123abc" -AsPlainText -Force } -Verifiable

            Mock Set-ItemProperty {} -Verifiable

            Mock Invoke-Expression {}
            
            Mock Edit-HistoryFile {}

            Mount-TrueCrypt -Name 'BobsTaxDocs' -KeyfilePath "C:\Users\Bob\Music\ABC.mp3"

            It "Should of called internal functions..." {
                Assert-VerifiableMocks
            }

            It "Should of called Invoke-Expression with the value being used in this comparison operator..." {
                Assert-MockCalled Invoke-Expression -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $Command -eq "& TrueCrypt /keyfile 'C:\Users\Bob\Music\ABC.mp3' /explore /password '123abc' /volume 'C:\Users\Bob\Documents\BobsContainer' /quit /auto /letter 'T'"
                }
            }
        }
    }
    
    Context "with SecureString..." {
        InModuleScope PSTrueCrypt {
            Mock Get-PSTrueCryptContainer { 
            @{
                TrueCryptContainerPath = "C:\Users\Bob\Documents\BobsContainer"
                PreferredMountDrive = "T";
                Product = "TrueCrypt";
                Timestamp = 0x00000000
            }} -Verifiable

            Mock Invoke-Expression {}
            
            Mock Edit-HistoryFile {} -Verifiable

            $SecureString = ConvertTo-SecureString '123abc' -AsPlainText -Force

            Mount-TrueCrypt -Name 'BobsTaxDocs' -KeyfilePath "C:\Users\Bob\Music\ABC.mp3" -Password $SecureString

            It "Should of called internal functions..." {
                Assert-VerifiableMocks
            }

            It "Should of called Invoke-Expression with the value being used in this comparison operator..." {
                Assert-MockCalled Invoke-Expression -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $Command -eq "& TrueCrypt /keyfile 'C:\Users\Bob\Music\ABC.mp3' /explore /password '123abc' /volume 'C:\Users\Bob\Documents\BobsContainer' /quit /auto /letter 'T'"
                }
            }
        }
    }
}