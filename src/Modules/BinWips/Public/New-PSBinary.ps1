function New-PSBinary
{
   <#
    .SYNOPSIS
       Creates a new PowerShell binary.
    .DESCRIPTION
       Generates a .EXE from a script.
    .EXAMPLE
       New-PSBinary -ScriptBlock {Get-Process}
       
       Creates a file in the current directory named PSBinary.exe which runs get-process
    .EXAMPLE
       New-PsBinary MyScript.ps1

       Creates an exe in the current directory named MyScript.exe
    #>
   [CmdletBinding()]
   [Alias()]
   [OutputType([int])]
   Param
   (
      # The powershell command to convert into a program
      # cannot be combined with `InFile`
      [Parameter(Mandatory = $true,
         ValueFromPipelineByPropertyName = $true,
         Position = 0,
         ParameterSetName = 'Inline')]
      $ScriptBlock,

      # Source Script file
      [string]
      [Parameter(Mandatory = $true,
         ValueFromPipelineByPropertyName = $true,
         Position = 0,
         ParameterSetName = 'File')]
      $InFile,

      # Namespace for the generated program. 
      # This parameter is trumped by -Tokens, so placing a value here will be overriden by
      # whatever is in -Tokens
      # So if you did -Namespace A -Tokens @{Namespace='B'} Namespace would be set to B not A
      # Must be a valid C# namespace
      # Defaults to PSBinary
      [string]
      $Namespace = "PSBinary",

      # Class name for the generated program
      # This parameter is trumped by -Tokens, so placing a value here will be overriden
      # by whatever is in -Tokens
      # So if you did -ClassName A -Tokens @{ClassName='B'} ClassName would be set to B not A
      # must be a valid c# class name and cannot be equal to -Namespace
      # Defaults to Program
      $ClassName = "Program",

      # Name of the .exe to generate. Defaults to the -InFile (replaced with .exe) or 
      # PSBinary.exe if a script block is inlined
      [string]
      $OutFile,

      <# Hashtable of assembly attributes to apply to the assembly level.
             - list of defaults here: https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/attributes/global
             - custom attributes can also be aplied.
             - Invalid attributes will throw a c# compiler exception
             - Attributes are applied in addition to the defaults unless -NoDefaultAttributes
        #>
      [hashtable]
      $AssemblyAttributes,

      <#
            Exclude default attributes from being applied to PSBinary.
            Unless this is included some default attributes will be applied to the program. 
            So that other scripts/programs can identify it as a BinWips. 
        #>
      [switch]
      $NoDefaultAttributes,

      <# Hashtable of assembly attributes to apply to the class.
             - Any valid c# class attribute can be applied
             - Invalid attributes will throw a c# compiler exception
             - Attributes are applied in addition to the defaults unless -NoDefaultAttributes
        #>
      [hashtable]
      $ClassAttributes,
        

      <#
            Override the default class template.
            - BinWips Tokens (a character sequence such as beginning with {# and ending with #}) can be included
              and will be replaced with the matching token either from defaults or the -Tokens paramter.
            - If a BinWips exists with out a matching value in -Tokens an exception is thrown.
            - Example: In the default template there is namespace '{#PSNameSpace#} {...}' when compiled
              {#PSNamespace#} is replaced with PSBinary to produce namesapce PSBinary {...}
        #>
      [string]
      $ClassTemplate = @"
// Generaed by BinWips {#BinWipsVersion#}
using System;
using BinWips;
using System.Management.Automation; 

// attributes which can be used to identify this assembly as a BinWips
// https://stackoverflow.com/questions/1936953/custom-assembly-attributes
[assembly: BinWips("{#BinWipsVersion#}")]

// main namespace
namespace {#Namespace#} {

      class {#ClassName#} {
         public static void Main(string[] args) {
            var powerShell = PowerShell.Create();
            
            // script is inserted in base64 so we need to decode it
            var runtimeSetup = DecodeBase64("{#RuntimeSetup#}");
            var script = DecodeBase64("{#Script#}");
            
            // build runspace and execute it
            // additional setup could be added 
            // by default we do an out string so that
            // console output looks nice 
            Console.WriteLine(runtimeSetup);
            powerShell.AddScript(runtimeSetup)
                        .AddScript(script)
                        .AddCommand("Out-String");
            var results = powerShell.Invoke();

            // output the results
            foreach(var result in results){
                  Console.WriteLine(result);
            }
         }
         static string DecodeBase64(string encoded){
            var decodedBytes = Convert.FromBase64String(encoded);
            var text = System.Text.Encoding.Unicode.GetString(decodedBytes);
            return text;
         }
      }    
}
"@,

      <#
            Hashtable of tokens to replace in the class template. 
            Exclude the '{#' and '#}' in the keys. 
            
            Example:
            -Tokens @{Namespace='CustomNamespace';ClassName='MyCoolClass'} 

            Reserved Tokens 
            ---------------
            {#Script#} The script content to compile

        #>
      [hashtable]
      $Tokens,

      # Additional C# Compiler parameters you want to pass (e.g. references)
      [string[]]
      $CscArgumentList,

      # Not sure if this is gonna be a thing yet, but provide option to set default runtime customizations
      $PsRuntimeModifications,

      # Directory to place output in, defaults to current directory
      # Dir will be created if it doesn't already exist. 
      [string]
      $OutDir,

      # Change the directory where work will be done defaults to 'obj' folder in current directory
      # Use -Clean to clean this directory before building
      # Dir will be created if it doesn't already exist. 
      [string]
      $ScratchDir,

      # Clean the scratch directory before building
      # As compared to -KeepScratchDir which removes scratch dir *after* build. 
      [switch]
      $Clean,

      # After build don't remove the scratch dir.
      # As compared to -Clean which removes all files in scratch dir *before* build. 
      [switch]
      $KeepScratchDir,

      # Overrite -OutFile if it already exists
      [switch]
      $Force, 

      <# List of files to include with the app 
             - If -NoEmbedResources is specified then files are embedded in the exe.
                - Files are copied to out dir with exe if they don't already exist
             - Else files must be referenced specially (see below)

           To call files in script (if -NoEmbedresources is *not* included):
           `$myFile = Get-PsBinaryResource FileName.ext`
           where `FileName.ext` is the file you want to use. 
           This returns the content of the file, not a path to it.

           Only use this if you want to package things like settings files
           or images. Otherwise files are accessed normally by the generated exe.
        #>
      [string[]]
      $Resources,

      # Don't embed any resource specifed by -Resources
      # instead they are copied to out dir if they don't already exist
      [switch]
      $NoEmbedResources,
        
      # Output to a .NET .dll instead of an .exe
      [switch]
      $Library
   )

   Begin
   {
   }
   Process
   {
      <#
         Basic procedure is as follows:
         1. Verify params and perform setup (create dirs, clean, etc.)
         2. Read in script file if needed
         3. Base64 encode script for easy handling (no dealing with quotes)
         4. Inser script and replace tokens in class template
         5. Output class + additional files to .cs files in scratch dur
            - Maybe add an additional step here in the future to run 
              preprocessing on c# files (allow a script block -PreprocessBlock argument)
         6. Run C# compiler over those files and produce an exe in the out dir
         7. Cleanup
       #>

      # 1. 
      $inline = $PSCmdlet.ParameterSetName -eq 'Inline'
      if (!$inline -and !(Test-Path $InFile))
      {
         throw "Error: $InFile could not be found or you do not have access"
      }

      # flags for later
      $hasTokens = $PSBoundParameters.ContainsKey('Tokens')
      $hasClassAttributes = $PSBoundParameters.ContainsKey('ClassAttributes')
      $hasAssemblyAttributes = $PSBoundParameters.ContainsKey('AssemblyAttributes')
      $hasOutDir = $PSBoundParameters.ContainsKey('OutDir')
      $hasScratchDir = $PSBoundParameters.ContainsKey('ScratchDir')
      $hasOutFile = $PSBoundParameters.ContainsKey('HasOutFile')
      $hasResources = $PSBoundParameters.ContainsKey('Resources')
      
      # TODO: Reference a newer version of the PowerShell SDK
      $powerShellSDK = "C:\Windows\assembly\GAC_MSIL\System.Management.Automation\1.0.0.0__31bf3856ad364e35\System.Management.Automation.dll"
      $dotNetPath = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe" 

      if ($Library)
      {
         $target = "library"
      }
      else
      {
         $target = "exe"
      }

      if (!$hasOutDir)
      {
         $OutDir = Get-Location
      }
      if (!$hasScratchDir)
      {
         $ScratchDir = "$(Get-Location)\obj"
      }
      if (!$hasOutFile)
      {
         if ($inline)
         {
            $OutFile = "$OutDir\PSBinary.exe"
         }
         else
         {
            $OutFile = $InFile.Replace(".ps1", ".exe")
         }
         
      }

      $runtimeSetupScript = @"
      function Get-PSBinaryResource {
         [cmdletbinding()]
         param (
            [Parameter(Mandatory=`$true,Position=0)]
            [string] `$Path
         )
         `$asm = [System.Reflection.Assembly]::LoadFile("`$(pwd)\{#AssemblyPath#}")
         `$stream = `$asm.GetManifestResourceStream(`$Path)
         `$reader = [System.IO.StreamReader]::new(`$stream)
         `$result = `$reader.ReadToEnd()
         `$stream.Close()
         `$stream.Dispose()
         `$reader.Close()
         `$reader.Dipose();
         return `$result 
      }     
"@

      $runtimeSetupScript = $runtimeSetupScript | Set-PSBinaryToken -Key AssemblyPath -Value ($OutFile.TrimStart('.')) -Required
      $encodedRuntimeSetup = [Convert]::ToBase64String(([System.Text.Encoding]::Unicode.GetBytes($runtimeSetupScript)))
      $cscArgs = @("-out:$OutFile", 
         "/reference:$powerShellSDK",
         "/target:$target"
      )
      $cscArgs += $CscArgumentList
   
      # Create directories
      [System.IO.Directory]::CreateDirectory($ScratchDir)
      [System.IO.Directory]::CreateDirectory($OutDir)
      # TODO: Clean out dir if specified
      # TODO: Handle Resources
      if ($hasResources)
      {
         if ($NoEmbedResources)
         {
            #TODO:
         }
         else
         {
            foreach ($r in $Resources)
            {
               #https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/compiler-options/resource-compiler-option
               $cscArgs += "-resource:$r"
            }
         }
      }
     
      # 2. 
      if (!$inline)
      {
         $psScript = Get-Content $InFile
      }
      else
      {
         $psScript = $ScriptBlock
      }

      # 3. (https://stackoverflow.com/questions/15414678/how-to-decode-a-base64-string)
      $encodedScript = [Convert]::ToBase64String(([System.Text.Encoding]::Unicode.GetBytes($psScript)))
      
      # 4. 
      $csProgram = $ClassTemplate | Set-PSBinaryToken -Key Script -Value $encodedScript `
      | Set-PSBinaryToken -Key RuntimeSetup -Value $encodedRuntimeSetup -Required `
      | Set-PSBinaryToken -Key ClassName -Value $ClassName -Required `
      | Set-PSBinaryToken -Key Namespace -Value $Namespace -Required `
      | Set-PSBinaryToken -Key BinWipsVersion -Value "0.1"

      if ($hasAssemblyAttributes)
      {
         # TODO: preformat assembly attributes
         # $csProgram = $csProgram | Set-PSBinaryToken -Key AssemblyAttributes -Value 
      }
      if ($hasClassAttributes)
      {
         # TODO: preformat class attributes
         # $csProgram = $csProgram | Set-PSBinaryToken -Key ClassAttributes -Value 
      }
      if ($hasTokens)
      {
         $Tokens.GetEnumerator() | ForEach-Object {
            $csProgram = $csProgram | Set-PSBinaryToken -Key $_.Key -Value $_.Value 
         } 
      }
      # 5. 
      $csProgram | Out-File "$ScratchDir\PSBinary.cs" -Encoding utf8 -Force:$Force

      # TODO: Move to parameter
      $attributesTemplate = @"
using System;

namespace BinWips {
    [AttributeUsage(AttributeTargets.Assembly)]
    public class BinWipsAttribute : Attribute {
        public string Version {get;set;}
        public BinWipsAttribute(){}
        public BinWipsAttribute(string version){Version = version;}
    }
}
"@
      $attributesTemplate | Out-File "$ScratchDir\BinWipsAttr.cs" -Encoding utf8 -Force:$Force

      # 6. 
      $cscArgs += @("$ScratchDir\PSBinary.cs", 
         "$ScratchDir\BinWipsAttr.cs") # add files to args last
      $x = "$dotNetPath $cscArgs"
      Invoke-Expression $x

      # 7.
      # TODO: Cleanup
      if (!$KeepScratchDir)
      {
         #Remove-Item $ScratchDir -Recurse
      }
      
   }
   End
   {
   }
}