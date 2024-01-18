﻿# Bflat linux urL: https://github.com/bflattened/bflat/releases/download/v8.0.1/bflat-8.0.1-linux-glibc-x64.tar.gz
# Bflat windows url: https://github.com/bflattened/bflat/releases/download/v8.0.1/bflat-8.0.1-windows-x64.zip
# TODO: At some point update to grab latest version for all availavle platforms and add them all to the repo
# Download both and unzip so that the files are underneath new folders  src/Modules/BinWips/files/bflat/linux and  src/Modules/BinWips/files/bflat/windows
$linUrl = "https://github.com/bflattened/bflat/releases/download/v8.0.1/bflat-8.0.1-linux-glibc-x64.tar.gz"
$winUrl = " https://github.com/bflattened/bflat/releases/download/v8.0.1/bflat-8.0.1-windows-x64.zip"
$linOut = "bflat-linux.tar.gz"
$winOut = "bflat-windows.zip"
$linDir = "$PSScriptRoot/../src/Modules/BinWips/files/bflat/linux"
$winDir = "$PSScriptRoot/../src/Modules/BinWips/files/bflat/windows"

[System.IO.Directory]::CreateDirectory($linDir) | Out-Null
[System.IO.Directory]::CreateDirectory($winDir) | Out-Null

Invoke-WebRequest -Uri $linUrl -OutFile $linOut
Invoke-WebRequest -Uri $winUrl -OutFile $winOut


# need to use tar -xvzf on the linux file and quiet mode
tar -xzf $linOut -C $linDir
Expand-Archive -Path $winOut -DestinationPath $winDir

Remove-Item $linOut
Remove-Item $winOut

