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

#Run a test with the current version of PowerShell
    if(-not $Finalize)
    {
        "`n`tSTATUS: Testing with PowerShell $PSVersion`n"

        New-Item $ENV:OUT_TEST -ItemType Directory
        Set-Location $ENV:OUT_TEST
        refreshenv

        # on fresh install of Pester, the name seems to work using 'Pester' and not 'pester'.
        # When cached, 'pester' is used.  Hence, Import-Module is case-sensitive
        Get-Module
        try {
          Import-Module Pester
        } catch {
          Import-Module pester
        }
        Get-Module
        # imports PSTrueCrypt by name
        Import-Module -Name $ENV:APPVEYOR_BUILD_FOLDER

        Invoke-Pester -Path "$ENV:APPVEYOR_BUILD_FOLDER\Test" -OutputFormat NUnitXml -OutputFile "$ENV:OUT_TEST\$TestFile" -PassThru | `
            Export-Clixml -Path "$ENV:OUT_TEST\PesterResults$PSVersion.xml"
    }

#If finalize is specified, check for failures and
    else
    {
        #Show status...
            $AllFiles = Get-ChildItem -Path $ENV:OUT_TEST\*Results*.xml | Select-Object -ExpandProperty FullName
            "`n`tSTATUS: Finalizing results`n"
            "COLLATING FILES:`n$($AllFiles | Out-String)"

        #Upload results for test page
            Get-ChildItem -Path "$ENV:OUT_TEST\TestResultsPS*.xml" | Foreach-Object {

                $Address = "https://ci.appveyor.com/api/testresults/nunit/$($ENV:APPVEYOR_JOB_ID)"
                $Source = $_.FullName

                "UPLOADING FILES: $Address $Source"

                (New-Object 'System.Net.WebClient').UploadFile( $Address, $Source )
            }

        #What failed?
            $Results = @( Get-ChildItem -Path "$ENV:OUT_TEST\PesterResults*.xml" | Import-Clixml )

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
