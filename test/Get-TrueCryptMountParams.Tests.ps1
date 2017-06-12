Describe "Get-TrueCryptMountParams when called..." {
    It "with timestamp" {
    $ExpectedResults = "& TrueCrypt /keyfile 'D:\.AlicesTrueCryptKeyfile' /mountoption timestamp /quit /volume 'H' /explore /password '{0}' /letter 'M' /auto";
        Get-TrueCryptMountParams -TrueCryptContainerPath 'H' -PreferredMountDrive 'M' -Product 'TrueCrypt' -KeyfilePath 'D:\.AlicesTrueCryptKeyfile' -Timestamp $True | Should BeExactly $ExpectedResults
    }

    It "without timestamp" {
    $ExpectedResults = "& TrueCrypt /keyfile 'D:\.AlicesTrueCryptKeyfile' /explore /password '{0}' /volume 'H' /quit /auto /letter 'M'";
        Get-TrueCryptMountParams -TrueCryptContainerPath 'H' -PreferredMountDrive 'M' -Product 'TrueCrypt' -KeyfilePath 'D:\.AlicesTrueCryptKeyfile' -Timestamp $False | Should BeExactly $ExpectedResults
    }

    It "with timestamp and VeraCrypt" {
    $ExpectedResults = "& VeraCrypt /keyfile 'D:\.AlicesTrueCryptKeyfile' /explore /password '{0}' /volume 'H' /quit /auto /letter 'M'";
        Get-TrueCryptMountParams -TrueCryptContainerPath 'H' -PreferredMountDrive 'M' -Product 'VeraCrypt' -KeyfilePath 'D:\.AlicesTrueCryptKeyfile' -Timestamp $False | Should BeExactly $ExpectedResults
    }
}