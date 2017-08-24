New-Object psobject (Get-Content $ENV:APPVEYOR_BUILD_FOLDER\PSTrueCrypt.psd1 -Raw | Invoke-Expression) -OutVariable Manifest | Out-Null
New-Item $ENV:OUT_BUILD -ItemType Directory

Push-Location
Set-Location $ENV:OUT_BUILD

$ENV:APPVEYOR_BUILD_FOLDER | Get-ChildItem -Recurse -File | ForEach-Object {

    $SubdirectoryPath = ($_.FullName -split "PSTrueCrypt\\").Get(1)

    if($Manifest.FileList -contains $SubdirectoryPath) {

        Join-Path $ENV:OUT_BUILD -ChildPath $SubdirectoryPath | Split-Path -Parent -OutVariable DestinationParent | Out-Null

        if((Test-Path $DestinationParent) -eq $False) {
            $DirectoryInfo = New-Item $DestinationParent -ItemType Directory
        } else {
            $DirectoryInfo = Get-Item $DestinationParent
        }

        $_.FullName | Copy-Item -Destination $DirectoryInfo
    }
}

Pop-Location
