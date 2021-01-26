param($String1,[switch]$Switch1)

function Get-PSBinaryResource {
   [cmdletbinding()]
   param (
      [Parameter(Mandatory=$true,Position=0)]
      [string] $Path
   )
   $asm = [System.Reflection.Assembly]::LoadFile("$(pwd)\C:\Users\Darin_000\source\repos\d-carrigg\BinWips\tests\Parameters\Script.exe")
   $stream = $asm.GetManifestResourceStream($Path)
   $reader = [System.IO.StreamReader]::new($stream)
   $result = $reader.ReadToEnd()
   $stream.Close()
   $stream.Dispose()
   $reader.Close()
   $reader.Dipose();
   return $result 
}     
"Hello World"
"Params are:"
$MyInvocation.BoundParameters | Format-Table | Out-String

