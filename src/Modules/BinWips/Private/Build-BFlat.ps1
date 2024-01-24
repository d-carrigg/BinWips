function Build-Bflat
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
         Position = 0)]
      $Script,

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

      [string]
      $Target,

      <# Hashtable of assembly attributes to apply to the assembly level.
             - list of defaults here: https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/attributes/global
             - custom attributes can also be aplied.
             - Invalid attributes will throw a c# compiler exception
             - Attributes are applied in addition to the defaults unless -NoDefaultAttributes
        #>
      [string[]]
      $AssemblyAttributes,


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
      $Tokens,

      # Additional C# Compiler parameters you want to pass (e.g. references)
      [string[]]
      $CscArgumentList,

      # Directory to place output in, defaults to current directory
      # Dir will be created if it doesn't already exist. 
      [string]
      $OutDir,

      # Change the directory where work will be done defaults to 'obj' folder in current directory
      # Dir will be created if it doesn't already exist. 
      [string]
      $ScratchDir,


      # Overrite -OutFile if it already exists
      [switch]
      $Force, 

      <#
        List of .NET assemblies to reference. 
      #>
      [string[]]
      $References,

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
      # useful when publishing
      [switch]
      $NoEmbedResources,

      # The platform to target
      [string]
      [ValidateSet('Linux', 'Windows')]
      $Platform,
  
      # The architecture to target
      [string]
      [ValidateSet('x86', 'x64', 'arm64')]
      $Architecture,

      [switch]
      $Cleanup,

      <#
        Which edition of PowerShell to target (PowerShell Core vs Windows PowerShell). 
        If not specified, defaults to the edition of PowerShell that is running the cmdlet.
        So if this function is run from pwsh, it will default to PowerShell Core.
        If this function is run from powershell.exe, it will default to Windows PowerShell.

        PowerShellEdition='Desktop' is only supported on Windows PowerShell 5.1 and newer. 
        If you try to use  PowerShellEdition='Desktop' and Platform='Linux', an error will be thrown. 
      #>
      [string]
      [ValidateSet('Core', 'Desktop')]
      $PowerShellEdition
      
   )

   Begin
   {
   }
   Process
   {
      $dotNetPath = (Get-Command bflat -ErrorAction SilentlyContinue).Source

      # Locate the compiler
      $moduleRoot = Split-Path -Path $PSScriptRoot -Parent
      if ([string]::IsNullOrWhiteSpace($dotNetPath) -eq $false)
      {
         #Write-Verbose "Found bflat at $dotNetPath"
      }
      elseif ($IsWindows)
      {
         $dotNetPath = "$moduleRoot/files/bflat/windows/bflat.exe"
      }
      else
      {
         $dotNetPath = "$moduleRoot/files/bflat/linux-glibc/bflat"
      }

      if (!(Test-Path $dotNetPath))
      {
         throw "Could not find bflat at $dotNetPath"
      }
    
      $cscArgs = @("build",
         "--out", "$OutFile", 
         "--target", "$target",
         "--no-debug-info", # Don't create a .pdb
         "--os", "$($Platform.ToLower())",
         "--arch", "$($Architecture.ToLower())"
         #"-i", "Main"
      )
      if ($null -ne $CscArgumentList -and $CscArgumentList.Length -gt 0)
      {
         $cscArgs += $CscArgumentList
      }
      
      if ($Resources -and $NoEmbedResources)
      {
         # Copy resources to out dir
         foreach ($r in $Resources)
         {
            $rName = Split-Path -Path $r -Leaf
            $outPath = Join-Path -Path $OutDir -ChildPath $rName
            if (!(Test-Path $outPath))
            {
               Copy-Item -Path $r -Destination $outPath
            }
         }

      }
      elseif ($Resources)
      {
         foreach ($r in $Resources)
         {
            #https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/compiler-options/resource-compiler-option
            $cscArgs += "--resource"
            $cscArgs += $r
         }
      }

      if ($References)
      {
         $cscArgs += "--reference"
         foreach ($r in $References)
         {
            $cscArgs += $r
         }
      }
     
      # Run C# compiler over those files and produce an exe in the out dir
      $cscArgs += "$ScratchDir/PSBinary.cs"
      $cscArgs += "$ScratchDir/BinWipsAttr.cs"

      $guid = [guid]::NewGuid().ToString()
      $Tokens['BinWipsPipeGuid'] = $guid

      $funcArgs = @{
         Script             = $Script
         Namespace          = $Namespace
         ClassName          = $ClassName
         OutFile            = $OutFile
         AssemblyAttributes = $AssemblyAttributes
         ClassAttributes    = $ClassAttributes
         ClassTemplate      = $ClassTemplate
         AttributesTemplate = $AttributesTemplate
         Tokens             = $Tokens
         OutDir             = $OutDir
         Cleanup            = $Cleanup
         Force              = $Force
         CompilerPath       = $dotNetPath
         CompilerArgs       = $cscArgs
         ScratchDir         = $ScratchDir
         PowerShellEdition  = $PowerShellEdition
      }

      Write-BinWipsExe @funcArgs

   }
   End
   {
   }
}