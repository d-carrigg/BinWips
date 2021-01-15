$pth = Resolve-Path  "$PSScriptRoot\..\..\src\Modules\BinWips\BinWips.psd1" 
rm "$PSScriptRoot\*" -Exclude "*.ps1" -Recurse

Import-Module $pth -Force

New-PSBinary -ScriptBlock {Write-Host "It's aliBRARY!"} -OutDir $PSScriptRoot  -ErrorAction Stop -Library

#. "$PSScriptRoot\PSBinar.exe"