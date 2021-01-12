$pth = Resolve-Path  "$PSScriptRoot\..\..\src\Modules\BinWips\BinWips.psd1" 
rm "$PSScriptRoot\*" -Exclude "*.ps1" -Recurse

Import-Module $pth -Force
