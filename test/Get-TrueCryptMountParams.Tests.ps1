Describe "Get-TrueCryptMountParams when called..." {
    InModuleScope PSTrueCrypt {
        It "with timestamp" {
        $ExpectedResults = "& TrueCrypt /keyfile 'C:\Users\Bob\Music\ABC.mp3' /mountoption timestamp /quit /volume 'C:\Users\Bob\Documents\BobsContainer' /explore /password '{0}' /letter 'T' /auto";
            Get-TrueCryptMountParams -TrueCryptContainerPath 'C:\Users\Bob\Documents\BobsContainer' -PreferredMountDrive 'T' -Product 'TrueCrypt' -KeyfilePath 'C:\Users\Bob\Music\ABC.mp3' -Timestamp $True | Should BeExactly $ExpectedResults
        }

        It "without timestamp" {
        $ExpectedResults = "& TrueCrypt /keyfile 'C:\Users\Bob\Music\ABC.mp3' /explore /password '{0}' /volume 'C:\Users\Bob\Documents\BobsContainer' /quit /auto /letter 'T'";
            Get-TrueCryptMountParams -TrueCryptContainerPath 'C:\Users\Bob\Documents\BobsContainer' -PreferredMountDrive 'T' -Product 'TrueCrypt' -KeyfilePath 'C:\Users\Bob\Music\ABC.mp3' -Timestamp $False | Should BeExactly $ExpectedResults
        }

        It "with timestamp and VeraCrypt" {
        $ExpectedResults = "& VeraCrypt /keyfile 'C:\Users\Alice\Music\Courage.mp3' /explore /password '{0}' /volume 'C:\Users\Alice\Documents\AlicesContainer' /quit /auto /letter 'V'";
            Get-TrueCryptMountParams -TrueCryptContainerPath 'C:\Users\Alice\Documents\AlicesContainer' -PreferredMountDrive 'V' -Product 'VeraCrypt' -KeyfilePath 'C:\Users\Alice\Music\Courage.mp3' -Timestamp $False | Should BeExactly $ExpectedResults
        }
    }
}