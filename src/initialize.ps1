Add-Type -AssemblyName System.Windows.Forms

Set-Alias -Name mt -Value Mount-TrueCrypt
Set-Alias -Name dmt -Value Dismount-TrueCrypt
Set-Alias -Name dmt* -Value Dismount-TrueCryptForceAll

Get-ChildItem (Join-Path $PSScriptRoot *.ps1) -Exclude '*initialize.ps1' -Recurse | ForEach-Object {
    . $_.FullName
}

Start-SystemCheck