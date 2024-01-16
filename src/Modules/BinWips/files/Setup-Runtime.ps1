function Get-PSBinaryResource {
    [cmdletbinding()]
    param (
       [Parameter(Mandatory=$true,Position=0)]
       [string] $Path,
 
       [Parameter(Mandatory=$false,Position=1)]
       [swtich]$AsFile
    )
    $asm = [System.Reflection.Assembly]::LoadFile("{#AssemblyPath#}")
    $stream = $asm.GetManifestResourceStream($Path)
    $reader = [System.IO.StreamReader]::new($stream)
    $result = $reader.ReadToEnd()
    $stream.Close()
    $stream.Dispose()
    $reader.Close()
    $reader.Dipose()
    if(!$AsFile){
     return $result 
    } else {
     $tmpFile = [System.IO.Path]::GetTempFileName()
     $result | Out-File -Encoding unicode -FilePath $tmpFile
      return get-item $tmpFile
    }
   
 }     

#  function Write-Output {
#    param($InputObject) process {Write-Host $InputObject}
#  }