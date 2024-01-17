function Get-BinWipsResource {
   [Alias("Get-PSBinaryResource")]
    [cmdletbinding()]
    param (
       [Parameter(Mandatory=$true,Position=0)]
       [string] $Path,
 
       [Parameter(Mandatory=$false,Position=1)]
       [switch]$AsFile
    )
   $csharp = @"
   using System.IO;
   using System.IO.Pipes;
   using System;
   
   namespace BinWips.Runtime
   {
       public static class RuntimeUtils
       {
           public static string GetResource(string path)
           {
               var client = new NamedPipeClientStream("BinWipsPipe{#BinWipsPipeGuid#}");
               client.Connect();
                
               StreamReader reader = new StreamReader(client);
               StreamWriter writer = new StreamWriter(client);
   
               string input = path;
               writer.WriteLine(input);
               writer.Flush();
               var result = reader.ReadLine();
               return result;
           }
       }
   }
"@

    Add-Type $csharp
    [BinWips.Runtime.RuntimeUtils]::GetResource($Path)
   
 }     

#  function Write-Output {
#    param($InputObject) process {Write-Host $InputObject}
#  }