New-Object psobject (Get-Content .\PSTrueCrypt.psd1 -Raw | Invoke-Expression) -OutVariable Manifest | Out-Null

New-Item ("$env:APPVEYOR_BUILD_FOLDER\Out") -ItemType Directory

Get-ChildItem -Recurse -File | ForEach-Object {

    $SubdirectoryPath = ($_.FullName -split "PSTrueCrypt\\").Get(1)

    if($Manifest.FileList -contains $SubdirectoryPath) {

        Join-Path ("$env:APPVEYOR_BUILD_FOLDER\Out") -ChildPath $SubdirectoryPath | Split-Path -Parent -OutVariable DestinationParent | Out-Null

        if((Test-Path $DestinationParent) -eq $False) {
            $DirectoryInfo = New-Item $DestinationParent -ItemType Directory
        } else {
            $DirectoryInfo = Get-Item $DestinationParent
        }

        $_.FullName | Copy-Item -Destination $DirectoryInfo
    }
}

Publish-Module -Path ("$env:APPVEYOR_BUILD_FOLDER\Out") -NuGetApiKey $env:MyNuGetApiKey
