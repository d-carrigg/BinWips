Push-Location $PSScriptRoot
$pth = Resolve-Path  "$PSScriptRoot\..\..\src\Modules\BinWips\BinWips.psd1" 

rm "$PSScriptRoot\*" -Exclude "*.ps1" -Recurse

Import-Module $pth -Force

New-PSBinary -InFile "$PSScriptRoot\File1.ps1","$PSScriptRoot\File2.ps1" -OutDir $PSScriptRoot  -ErrorAction Stop

Write-Host "Running program..."
. "$PSScriptRoot\File2.exe"

Pop-Location