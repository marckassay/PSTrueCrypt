New-Object psobject (Get-Content $ENV:APPVEYOR_BUILD_FOLDER\PSTrueCrypt.psd1 -Raw | Invoke-Expression) -OutVariable Manifest | Out-Null
New-Item $ENV:OUT_DEPLOY -ItemType Directory
Set-Location $ENV:OUT_DEPLOY

$ENV:APPVEYOR_BUILD_FOLDER | Get-ChildItem -Recurse -File | ForEach-Object {

    $SubdirectoryPath = ($_.FullName -split "PSTrueCrypt\\").Get(1)

    if($Manifest.FileList -contains $SubdirectoryPath) {

        Join-Path $ENV:OUT_DEPLOY -ChildPath $SubdirectoryPath | Split-Path -Parent -OutVariable DestinationParent | Out-Null

        if((Test-Path $DestinationParent) -eq $False) {
            $DirectoryInfo = New-Item $DestinationParent -ItemType Directory
        } else {
            $DirectoryInfo = Get-Item $DestinationParent
        }

        $_.FullName | Copy-Item -Destination $DirectoryInfo
    }
}
Get-ChildItem -Recurse -File
Publish-Module -Path $ENV:OUT_DEPLOY -NuGetApiKey $ENV:MY_NUGET_API_KEY -WhatIf
