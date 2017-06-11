Describe "Test Dismount-TrueCrypt when called..." {
    
    BeforeEach {
        $OutTestPath = Split-Path -Path $PSScriptRoot -Parent | Join-Path -ChildPath "out/test/resources"
        
        Remove-Item -Path $OutTestPath -Recurse -ErrorAction Silently 
        
        Copy-Item "$PSScriptRoot/resources" -Destination $OutTestPath -Recurse
    }

    AfterEach {
        Split-Path -Path $PSScriptRoot -Parent | Join-Path -ChildPath "out" | Remove-Item -Recurse
    }
    
    Context "with valid Name" {
        InModuleScope PSTrueCrypt {
            Mock Get-PSTrueCryptContainer { 
            @{
                TrueCryptContainerPath = "$PSScriptRoot/test/resources/truecrypt"
                PreferredMountDrive = "T";
                Product = "TrueCrypt";
                Timestamp = 0x00000000
            }} -Verifiable

            Mock Invoke-Expression {}
            
            Dismount-TrueCrypt -Name 'true'

            It "Should of called Invoke-Expression with the value being used in this comparison operator..." {
                Assert-MockCalled Invoke-Expression -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $Command -eq "& TrueCrypt /dismount T /quit"
                }
            }
        }
    }
}