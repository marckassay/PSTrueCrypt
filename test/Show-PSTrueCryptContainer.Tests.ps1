Import-Module -Name .\StubModule

Describe "Show-PSTrueCryptContainer when called..." {
   
    Context "with 4 containers" {

        InModuleScope PSTrueCrypt {
            
            $SUT = $True

            Start-Transaction

            . .\resources\HKCU_Software_PSTrueCrypt_1.ps1

            Set-Location HKCU:\Software\PSTrueCrypt\Test -UseTransaction

            Show-PSTrueCryptContainers | Out-Default -OutVariable Containers

            It "Should of called Get-ChildItem which then outputs to console..." {
               $Containers.Count | Should Be 4
            }

            Undo-Transaction

            $SUT = $False
        }
    }
}