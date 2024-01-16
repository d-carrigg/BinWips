﻿function New-PSBinaryNewDotnet
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

      # Source Script file(s), order is important
      # Files added in order entered
      # Exe name is defaulted to last file in array
      [string[]]
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
      [string[]]
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
         4. Insert script and replace tokens in class template
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
      $hasOutFile = $PSBoundParameters.ContainsKey('OutFile')
      $hasResources = $PSBoundParameters.ContainsKey('Resources')
      $hasClassTemplate = $PSBoundParameters.ContainsKey('ClassTemplate')
      $hasAttributesTemplate = $PSBoundParameters.ContainsKey('AttributesTemplate')
      $runtime = "win-x64"
      $framework = "net8.0"
     
   
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

      if (!$hasOutDir)
      {
         $OutDir = $PWD
      }
      if (!$hasScratchDir)
      {
         $ScratchDir = "$PWD\obj"
      }
      if (!$hasOutFile)
      {
         if ($inline)
         {
            $OutFile = "$OutDir\PSBinary.$outExt"
         }
         elseif($multipleFiles)
         {
            $OutFile = $InFile[-1].Replace(".ps1", ".$outExt")
         }
         else
         {
            $OutFile = $InFile.Replace(".ps1", ".$outExt")
         }
         
      } 

      if(!$hasClassTemplate -and $Library)
      {
         $ClassTemplate = Get-Content -Raw "$PSScriptRoot\..\files\LibraryClassTemplate.cs"
      }
      elseif(!$hasClassTemplate)
      {
         $ClassTemplate = Get-Content -Raw "$PSScriptRoot\..\files\ClassTemplate.cs"
      }
      if(!$hasAttributesTemplate)
      {
         $AttributesTemplate = Get-Content -Raw "$PSScriptRoot\..\files\AttributesTemplate.cs"
      }

      $runtimeSetupScript = Get-Content -Raw "$PSScriptRoot\..\files\Setup-Runtime.ps1"

      $runtimeSetupScript = $runtimeSetupScript | Set-PSBinaryToken -Key AssemblyPath -Value ($OutFile.TrimStart('.')) -Required 
      Write-verbose "here"
      Write-Verbose $runtimeSetupScript
      $encodedRuntimeSetup = [Convert]::ToBase64String(([System.Text.Encoding]::Unicode.GetBytes($runtimeSetupScript)))
      $dotNetPath = "where.exe dotnet" | Invoke-Expression
      if ($dotNetPath -eq "INFO: Could not find files for the given pattern(s).")
      {
         Write-Error "dotnet not found. Please install dotnet core sdk 3.1 or later"
      }

      $cscArgs = @("publish", 
         "--nologo",
         "--runtime  $runtime",
         "--self-contained"
      )
      $cscArgs += $CscArgumentList
   
      # Create directories
      [System.IO.Directory]::CreateDirectory($ScratchDir)
      [System.IO.Directory]::CreateDirectory($OutDir)	
      # TODO: Clean out dir if specified
      # TODO: Handle Resources
      $ResourceXml = ""
      if ($hasResources)
      {
         if ($NoEmbedResources)
         {
            #TODO: Copy to out dir
         }
         else
         {
            foreach ($r in $Resources)
            {
               #https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/compiler-options/resource-compiler-option
               #$cscArgs += "--resource $r"
               $ResourceXml += "<EmbeddedResource Include=`"$r`" />`r`n"
            }
         }
      }
     
      # 2. 
      if ($inline)
      {
         $psScript = $ScriptBlock.ToString()
         
      }
      else
      { 
         $psScript = Get-Content $InFile -Raw
      }
 

      # 3. (https://stackoverflow.com/questions/15414678/how-to-decode-a-base64-string)
      # OLD:       $encodedScript = [Convert]::ToBase64String(([System.Text.Encoding]::Unicode.GetBytes($psScript)))
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
         Write-Verbose "Applying Assembly Attribuytes"
         $att = ""
         $AssemblyAttributes | % {
               $att += "$_`r`n"
         }
         if($att -eq $null)
         {
            Write-Error "Failed to build assembly attributes"
         }
         $csProgram = $csProgram | Set-PSBinaryToken -Key AssemblyAttributes -Value $att
      }
      else {
         $csProgram = $csProgram | Remove-PSBinaryToken -Key AssemblyAttributes
      }
      if ($hasClassAttributes)
      {
         Write-Verbose "Applying class attributes"
         $att = ""
         $ClassAttributes | % {
               $att += "$_`r`n"
         }
         if($att -eq $null)
         {
            Write-Error "Failed to build class attributes"
         }
         $csProgram = $csProgram | Set-PSBinaryToken -Key ClassAttributes -Value $att
      }
      else {
         $csProgram = $csProgram | Remove-PSBinaryToken -Key ClassAttributes
      }
      if ($hasTokens)
      {
         $Tokens.GetEnumerator() | ForEach-Object {
            $csProgram = $csProgram | Set-PSBinaryToken -Key $_.Key -Value $_.Value 
         } 
      }
      # 5. 
      $csProgram | Out-File "$ScratchDir\PSBinary.cs" -Encoding unicode -Force:$Force
 
      $attributesTemplate | Out-File "$ScratchDir\BinWipsAttr.cs" -Encoding unicode -Force:$Force

      $projfile = Get-Content -Raw "$PSScriptRoot\..\files\BinWipsProj.csproj"

   

      $projfile = $projfile | Set-PSBinaryToken -Key OutputType -Value $target `
                            | Set-PSBinaryToken -Key Framework -Value $framework `
                            | Set-PSBinaryToken -Key EmbededResources -Value $ResourceXml
                     
      $projfile | Out-File "$ScratchDir\BinWipsProj.csproj" -Encoding unicode -Force:$Force

      # 6. 
      $cscArgs += @("`"$ScratchDir\BinWipsProj.csproj`"")
      $x = "& `"$dotNetPath`" $cscArgs"
      Write-Verbose $x
      try {
         Push-Location $ScratchDir

         $results = Invoke-Expression $x
         Write-Host $results
      } finally {
         Pop-Location
      }

      Copy-Item "$ScratchDir/bin/Release/$framework/$runtime/publish/BinWipsProj.exe" $OutFile -Force:$Force

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