Import-Module PSTrueCrypt.psm1

Describe "Mount-TrueCrypt" {
    Context "Called with no name" {
        <#
        Mock -ModuleName PSTrueCrypt Get-PSTrueCryptContainer { return 1.1 }
        Mock -ModuleName PSTrueCrypt Get-TrueCryptMountParams { return 1.1 }
        Mock -ModuleName PSTrueCrypt Test-IsAdmin { return 1.1 }
        Mock -ModuleName PSTrueCrypt Read-Host { return 1.1 }
        Mock -ModuleName PSTrueCrypt Invoke-Expression { return 1.1 }
        #>
        It{
            Mount-TrueCrypt 
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
