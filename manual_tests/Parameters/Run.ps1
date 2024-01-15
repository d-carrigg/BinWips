$pth = Resolve-Path "$PSScriptRoot\..\..\src\Modules\BinWips\BinWips.psd1" 
rm "$PSScriptRoot\*" -Exclude "*.ps1" -Recurse
Push-Location $PSScriptRoot
Import-Module $pth -Force

New-PSBinary -InFile "$PSScriptRoot\Script.ps1" -OutDir $PSScriptRoot  -Parameters "param(`$String1,[switch]`$Switch1)"  -ErrorAction Stop


Write-Host "Running program..."
. "$PSScriptRoot\Script.exe" "-String1 abc -Switch1"

Pop-Location 