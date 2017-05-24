Add-Type -AssemblyName System.Windows.Forms

Set-Alias -Name mt -Value Mount-TrueCrypt
Set-Alias -Name dt -Value Dismount-TrueCrypt
Set-Alias -Name dtf -Value Dismount-TrueCryptForceAll

Get-ChildItem (Join-Path $PSScriptRoot *.ps1) -Exclude '*initialize.ps1' -Recurse | ForEach-Object {
    . $_.FullName
}

Start-SystemCheck