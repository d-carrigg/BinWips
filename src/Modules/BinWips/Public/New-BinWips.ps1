function New-BinWips
{
   <#
    .SYNOPSIS
       Creates a new PowerShell binary.
    .DESCRIPTION
       Generates a .EXE from a script.
    .EXAMPLE
       New-BinWips -ScriptBlock {Get-Process}
       
       Creates a file in the current directory named PSBinary.exe which runs get-process
    .EXAMPLE
       New-BinWips MyScript.ps1

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

      # Source Script file(s), order is important
      # Files added in order entered
      # Exe name is defaulted to last file in array
      [string[]]
      [Parameter(Mandatory = $true,
         ValueFromPipelineByPropertyName = $true,
         Position = 0,
         ParameterSetName = 'File')]
      $InFile,

      # Directory to place output in, defaults to current directory
      # Dir will be created if it doesn't already exist. 
      [string]
      $OutDir,

      # Change the directory where work will be done defaults to 'obj' folder in current directory
      # Use -Clean to clean this directory before building
      # Dir will be created if it doesn't already exist. 
      [string]
      $ScratchDir,

      # Name of the .exe to generate. Defaults to the -InFile (replaced with .exe) or 
      # PSBinary.exe if a script block is inlined
      [string]
      $OutFile,


      # Clean the scratch directory before building
      # As compared to -KeepScratchDir which removes scratch dir *after* build. 
      [switch]
      $Cleanup,

      
      # Overrite -OutFile if it already exists
      [switch]
      $Force, 

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



      [string]
      $Target,

      <# Hashtable of assembly attributes to apply to the assembly level.
             - list of defaults here: https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/attributes/global
             - custom attributes can also be aplied.
             - Invalid attributes will throw a c# compiler exception
        #>
      [string[]]
      $AssemblyAttributes,


      <# Hashtable of assembly attributes to apply to the class.
             - Any valid c# class attribute can be applied
             - Invalid attributes will throw a c# compiler exception
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
      $ClassTemplate,

      
      <#
            Override the default attributes template.
            BinWips Tokens not supported.
        #>
      [string]
      $AttributesTemplate,

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
      $Tokens = @{},

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
      $Library,

      # The platform to target
      [string]
      [ValidateSet('Linux', 'Windows')]
      $Platform,

      # The architecture to target
      [string]
      [ValidateSet('x86', 'x64', 'arm64')]
      $Architecture,

      # Additional C# Compiler parameters you want to pass (e.g. references)
      [string[]]
      $CscArgumentList
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
         4. Insert script and replace tokens in class template
         5. Output class + additional files to .cs files in scratch dir
            - Maybe add an additional step here in the future to run 
              preprocessing on c# files (allow a script block -PreprocessBlock argument)
         6. Run C# compiler over those files and produce an exe in the out dir
         7. Cleanup
       #>

      # 1. Verify params and perform setup (create dirs, clean, etc.)
      $inline = $PSCmdlet.ParameterSetName -eq 'Inline'
      if (!$inline -and !(Test-Path $InFile))
      {
         throw "Error: $InFile could not be found or you do not have access"
      }

      # flags for later
      $hasOutDir = $PSBoundParameters.ContainsKey('OutDir')
      $hasScratchDir = $PSBoundParameters.ContainsKey('ScratchDir')
      $hasOutFile = $PSBoundParameters.ContainsKey('OutFile')
      $hasClassTemplate = $PSBoundParameters.ContainsKey('ClassTemplate')
      $hasAttributesTemplate = $PSBoundParameters.ContainsKey('AttributesTemplate')
      $multipleFiles = !$inline -and ($InFile.Count -gt 0)

      if ($Library)
      {
         $target = "library"
         $outExt = ".dll"
      }
      else
      {
         $target = "exe"
         $outExt = "exe"
      }
      $currentDir = (Get-Location).Path
      if (!$hasOutDir)
      {
         $OutDir = $currentDir
      }
      if (!$hasScratchDir)
      {
         $ScratchDir = "$currentDir\.binwips"
      }
      if (!$hasOutFile)
      {
         if ($inline)
         {
            $OutFile = "$OutDir\PSBinary.$outExt"
         }
         elseif ($multipleFiles)
         {
            $OutFile = $InFile[-1].Replace(".ps1", ".$outExt")
         }
         else
         {
            $OutFile = $InFile.Replace(".ps1", ".$outExt")
         }
         
      } 
      # Create directories
      [System.IO.Directory]::CreateDirectory($ScratchDir)
      [System.IO.Directory]::CreateDirectory($OutDir)	


      if (!$hasClassTemplate -and $Library)
      {
         $ClassTemplate = Get-Content -Raw "$PSScriptRoot\..\files\LibraryClassTemplate.cs"
      }
      elseif (!$hasClassTemplate)
      {
         $ClassTemplate = Get-Content -Raw "$PSScriptRoot\..\files\ClassTemplate.cs"
      }
      if (!$hasAttributesTemplate)
      {
         $AttributesTemplate = Get-Content -Raw "$PSScriptRoot\..\files\AttributesTemplate.cs"
      }

      if ($inline)
      {
         $psScript = $ScriptBlock.ToString()
         
      }
      else
      { 
         $psScript = Get-Content $InFile -Raw
      }

      # If Platform and Architecture are not specified, use the current platform and architecture
      if (!$PSBoundParameters.ContainsKey('Platform') -and $IsWindows)
      {
         $Platform = 'Windows'
        
      }
      elseif (!$PSBoundParameters.ContainsKey('Platform') -and $IsLinux)
      {
         $Platform = 'Linux'
      }
      else
      {
         throw "Unsported platform"
      }

      if (!$PSBoundParameters.ContainsKey('Architecture') -and $IsWindows)
      {
         $Architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
      }

      [System.IO.Directory]::CreateDirectory($ScratchDir)
      [System.IO.Directory]::CreateDirectory($OutDir)

      $args = @{
         Script             = $psScript
         Namespace          = $Namespace
         ClassName          = $ClassName
         OutFile            = $OutFile
         Target             = $target
         AssemblyAttributes = $AssemblyAttributes
         ClassAttributes    = $ClassAttributes
         ClassTemplate      = $ClassTemplate
         AttributesTemplate = $AttributesTemplate
         Tokens             = $Tokens
         CscArgumentList    = $CscArgumentList
         OutDir             = $OutDir
         ScratchDir         = $ScratchDir
         Cleanup            = $Cleanup
         Force              = $Force
         Resources          = $Resources
         NoEmbedResources   = $NoEmbedResources
         Platform           = $Platform
         Architecture       = $Architecture
      }     

      Build-Bflat @args
      
   }
   End
   {
   }
}