# completely stolen from: https://github.com/RamblingCookieMonster/PSDiskPart

# This script will invoke pester tests
# It should invoke on PowerShell v2 and later
# We serialize XML results and pull them in appveyor.yml

#If Finalize is specified, we collect XML output, upload tests, and indicate build errors
param([switch]$Finalize)

#Initialize some variables, move to the project root
    #handle PS2
    if(-not $PSScriptRoot)
    {
        $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
    }
    $PSVersion = $PSVersionTable.PSVersion.Major
    $TestFile = "TestResultsPS$PSVersion.xml"
    $ProjectRoot = $ENV:APPVEYOR_BUILD_FOLDER
    Set-Location $ProjectRoot
   

#Run a test with the current version of PowerShell
    if(-not $Finalize)
    {
        "`n`tSTATUS: Testing with PowerShell $PSVersion`n"
        
        refreshenv

    Import-Module Pester
    # this uri was found in the console view of a build at, eg: ci.appveyor.com/project/marckassay/pstruecrypt/build/0.0.6.21
    Import-Module -Name C:\projects\PSTrueCrypt

        Invoke-Pester -Path "$ProjectRoot\Test" -OutputFormat NUnitXml -OutputFile "$ProjectRoot\$TestFile" -PassThru | `
            Export-Clixml -Path "$ProjectRoot\PesterResults$PSVersion.xml"
    }

#If finalize is specified, check for failures and 
    else
    {
        #Show status...
            $AllFiles = Get-ChildItem -Path $ProjectRoot\*Results*.xml | Select-Object -ExpandProperty FullName
            "`n`tSTATUS: Finalizing results`n"
            "COLLATING FILES:`n$($AllFiles | Out-String)"

        #Upload results for test page
            Get-ChildItem -Path "$ProjectRoot\TestResultsPS*.xml" | Foreach-Object {
        
                $Address = "https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)"
                $Source = $_.FullName

                "UPLOADING FILES: $Address $Source"

                (New-Object 'System.Net.WebClient').UploadFile( $Address, $Source )
            }

        #What failed?
            $Results = @( Get-ChildItem -Path "$ProjectRoot\PesterResults*.xml" | Import-Clixml )
            
            $FailedCount = $Results | `
                Select-Object -ExpandProperty FailedCount | `
                Measure-Object -Sum | `
                Select-Object -ExpandProperty Sum
    
            if ($FailedCount -gt 0) {

                $FailedItems = $Results |
                    Select-Object -ExpandProperty TestResult | `
                    Where-Object {$_.Passed -notlike $True}

                "FAILED TESTS SUMMARY:`n"
                $FailedItems | ForEach-Object {
                    $Test = $_
                    [pscustomobject]@{
                        Describe = $Test.Describe
                        Context = $Test.Context
                        Name = "It $($Test.Name)"
                        Result = $Test.Result
                    }
                } | `
                    Sort-Object Describe, Context, Name, Result | `
                    Format-List

                throw "$FailedCount tests failed."
            }
    }