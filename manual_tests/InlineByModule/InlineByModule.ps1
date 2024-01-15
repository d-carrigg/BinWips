$pth = Resolve-Path  "$PSScriptRoot\..\..\src\Modules\BinWips\BinWips.psd1" 
rm "$PSScriptRoot\*" -Exclude "*.ps1" -Recurse

Import-Module $pth -Force

New-PSBinary -ScriptBlock {"Hello World"} -OutDir $PSScriptRoot  -ErrorAction Stop

. "$PSScriptRoot\PSBinary.exe"