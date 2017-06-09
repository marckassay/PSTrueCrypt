Describe "Test Mount-TrueCrypt" {
    
    BeforeEach {
        $OutTestPath = Split-Path -Path $PSScriptRoot -Parent | Join-Path -ChildPath "out/test/resources"
        
        Remove-Item -Path $OutTestPath -Recurse -ErrorAction Silently 
        
        Copy-Item "$PSScriptRoot/resources" -Destination $OutTestPath
    }

    AfterEach {
        Remove-Item -Path $OutTestPath -Recurse
    }

    InModuleScope PSTrueCrypt {
        Mock Get-PSTrueCryptContainer { 
        @{
            TrueCryptContainerPath = "$PSScriptRoot/test/resources/truecrypt"
            PreferredMountDrive = "T";
            Product = "TrueCrypt";
            Timestamp = 0x00000000
        }} -Verifiable

        Mock Test-IsAdmin { return $True } -Verifiable

        Mock Read-Host { return  ConvertTo-SecureString "123abc" -AsPlainText -Force } -Verifiable

        Mock Set-ItemProperty {} -Verifiable

        Mock Invoke-Expression {}
        
        Mock Edit-HistoryFile {}

        Mount-TrueCrypt -Name 'true'

        It "Should of called internal functions..." {
            Assert-VerifiableMocks
        }

        It "Should of received expression equal to test case expression" {
            Assert-MockCalled Invoke-Expression -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                $Command -eq "& TrueCrypt /explore /password '123abc' /volume '/test/resources/truecrypt' /quit /auto /letter 'T'"
            }
        }
    }
    <#
    Context "Called with name" {

    }

    Context "Called with no KeyfilePath" {

    }

    Context "Called with KeyfilePath" {

    }

    Context "Called with no KeyfilePath and Password" {

    }
    #>
}