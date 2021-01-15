$pth = Resolve-Path  "$PSScriptRoot\..\..\src\Modules\BinWips\BinWips.psd1" 
rm "$PSScriptRoot\*" -Exclude "*.ps1" -Recurse

Import-Module $pth -Force

New-PSBinary -InFile 'File1.ps1','File2.ps1' -OutDir $PSScriptRoot  -ErrorAction Stop

. "$PSScriptRoot\File2.exe"