Import-Module -Name .\StubModule

Describe "Test Show-PSTrueCryptContainer when called..." {
   
    Context "while 4 containers are in registry" {

        InModuleScope PSTrueCrypt {
            
            $SUT = $True

            Start-Transaction

            . .\resources\HKCU_Software_PSTrueCrypt_Test1.ps1

            Set-Location HKCU:\Software\PSTrueCrypt\Test -UseTransaction

            Show-PSTrueCryptContainers | Out-Default -OutVariable Containers

            It "Should of internally called Get-ChildItem returning expected number of items..." {
               $Containers.Count | Should Be 4
            }

            Undo-Transaction

            $SUT = $False
        }
    }
   
    Context "while no containers are in registry" {

        InModuleScope PSTrueCrypt {
            
            $SUT = $True

            Start-Transaction

            New-Item -Path "HKCU:\Software\PSTrueCrypt\Test\" -Force -UseTransaction

            Set-Location HKCU:\Software\PSTrueCrypt\Test -UseTransaction

            Mock Out-Information {}

            Show-PSTrueCryptContainers -Debug

            It "Should of called Out-Information with 'NoPSTrueCryptContainerFound' value..." {
                Assert-MockCalled Out-Information -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $Key -eq 'NoPSTrueCryptContainerFound'
                }
            }

            Undo-Transaction

            $SUT = $False
        }
    }
}