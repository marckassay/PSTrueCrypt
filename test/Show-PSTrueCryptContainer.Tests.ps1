Import-Module -Name .\StubModule

Describe "Show-PSTrueCryptContainer when called..." {

    Context "with at least one container" {
        InModuleScope PSTrueCrypt {

            Mock Get-ChildItem { }

            Show-PSTrueCryptContainers

            It "Should of called Get-ChildItem which then outputs to console..." {
                Assert-MockCalled Get-ChildItem -ModuleName PSTrueCrypt -Times 1
            }
        }
    }
    <#
    Context "with no containers" {
        InModuleScope PSTrueCrypt {

            Mock Get-ChildItem { $null }
            
            Mock Out-Error {}
            # TODO: I may need to recode the try block where Get-ChildItem resides.  I think the 
            # exception that is causing unexpected results from Pester may come further down the pipeline.
            Show-PSTrueCryptContainers -ErrorAction Ignore

            It "Should of called Out-Error with 'SecurityRecommendment' value..." {
                Assert-MockCalled Out-Error -ModuleName PSTrueCrypt -Times 1 -ParameterFilter {
                    $Key -eq 'SecurityRecommendment'
                }
            }
        }
    } #>
}