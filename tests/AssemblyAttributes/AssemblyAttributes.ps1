$pth = Resolve-Path "$PSScriptRoot\..\Common\Common.ps1"
Write-Host $pth
. $pth
cd $PSScriptRoot

try {
    New-PSBinary -ScriptBlock {"Hello Assembly Attributes"} -AssemblyAttributes @('[assembly: System.Reflection.AssemblyVersionAttribute("4.3.2.1")]'
    ,'[assembly:System.Reflection.AssemblyFileVersionAttribute("4.3.2.1")]') -ErrorAction Stop 
}
catch {
    throw
}


$asm = [System.Reflection.Assembly]::LoadFile("$($PSScriptRoot)\PSBinary.exe")

$attItems = $asm.GetCustomAttributes($false)

$found = $false
foreach($att in $attItems)
{
   if( $att.TypeId.Name -eq 'AssemblyFileVersionAttribute'){$found = $true}
}
if(!$found)
{
    throw "Assembly Attribute failed to apply"
}

Remove-Variable asm

Remove-Module BinWips