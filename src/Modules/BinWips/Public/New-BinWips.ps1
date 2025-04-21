
function New-BinWips
{
   <#
    .SYNOPSIS
       Creates a new .exe from a script block or script file.
    .DESCRIPTION
       Generates a .EXE from a script. Support for parameters, interactive programs,
       cross-platform compiling, resource embedding. See examples for more information.
       Use Get-Help BinWips -Online to open the read me on github. 
    .NOTES
      This module is not associated with Bflat or the developers. The license for 
      Bflat (if installed through the module), can be found at:
         module_folder/BinWips/files/bflat/platform/License.txt 
    .EXAMPLE
       New-BinWips -ScriptBlock {Write-Host "Hello, World!"}
       # ./PSBinary.exe 
       # Hello, World!
       
       Creates a file in the current directory named PSBinary.exe which writes "Hello, World!" to the console
    .EXAMPLE
       New-BinWips MyScript.ps1
       # ./MyScript.exe
       Creates an exe in the current directory named MyScript.exe
   .EXAMPLE
      New-BinWips -ScriptBlock {
         param($foo)
         Write-Output "$foo"
      }
      # ./PSBinary.exe -foo "bar"
      
      Creates a program which accepts a parameter and writes it to the console
   .EXAMPLE
      New-BinWips -ScriptBlock {
         $input = Read-Host "What's your name?"
         Write-Host "Hello, $input!"
      }
      # ./PSBinary.exe
      # What's your name?: BinWips
      # Hello, BinWips!

      Create an interactive program (Read-Host works the same).
   .EXAMPLE
      New-BinWips -ScriptBlock {
         $fileContent = Get-PsBinaryResource "MyFile.txt"
         $fileContent += Get-PsBinaryResource "MyOtherFile.txt"
         Write-Output $fileContent
      } -Resources "MyFile.txt", "MyOtherFile.txt" -OutFile "MyProgram.exe"

      Embeddes the files MyFile.txt and MyOtherFile.txt into the exe and makes them accessible via Get-PsBinaryResource.
   .EXAMPLE 
      New-BinWips -ScriptBlock {
         Write-host "done"
      } -ClassTemplate @"
        // use tokens to replace values in the template, see -Tokens for more info
        namespace {#Namespace#} {
           public class MyClass {
              public static void Main(string[] args) {
                 //.. Custom Host class implementation
                 var x = "{#RuntimeSetip#}"; // ignored but required to be in template
                 var y = "{#Script#}"; // ignored but required to be in template
                 var ext = ".exe";
                 var p = System.Diagnostics.Process.Start("pwsh", "-NoProfile -NoLogo -Command \"Write-host 'Ignore Script'\"");
                 p.WaitForExit();
              }
           }
        }
"@

      Override the Class Template used for the C# program that runs the script. This example would ignore the passed in scripts
      and print "Ignore Script" to the console.
   .EXAMPLE
      New-BinWips -ScriptBlock  {echo "Only Runs on Win x64"} -Platform Windows -Architecture x64
      
      Creates a program which targets Windows x64. Valid Options are Windows/Linux and x86/x64/arm64.
      By default BinWips will target the current platform and architecture.
   .EXAMPLE
      New-BinWips -ScriptBlock  {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory=$true)]
                [string]$foo
            )
            Add-Type -AssemblyName System.Windows.Forms
            $form = New-Object System.Windows.Forms.Form
            $form.Text = "Hello World"
            $form.ShowDialog()
        } -Platform Windows -Architecture x64
      
      Creates a program that shows a window on Windows x64.
   .LINK
        https://github.com/d-carrigg/BinWips
    #>
   [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
   [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'BinWips is not plural')]
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

      # Change the directory where work will be done defaults to `.binwips` folder in current directory
      # Dir will be created if it doesn't already exist. 
      [string]
      $ScratchDir,

      # Name of the .exe to generate. Defaults to the -InFile (replaced with .exe) or 
      # PSBinary.exe if a script block is inlined
      [string]
      $OutFile,

      # Namespace for the generated program. 
      # This parameter is trumps -Tokens, so placing a value here will be override whatever is in -Tokens
      # So if you did -Namespace A -Tokens @{Namespace='B'} Namespace would be set to A not B
      # Must be a valid C# namespace
      # Defaults to PSBinary
      [string]
      $Namespace = "PSBinary",

      # Class name for the generated program
      # This parameter is trumps -Tokens, so placing a value here will override whatever is in -Tokens
      # So if you did -ClassName A -Tokens @{ClassName='B'} ClassName would be set to A not B
      # must be a valid c# class name and cannot be equal to -Namespace
      # Defaults to Program
      $ClassName = "Program",


      <# List of assembly attributes to apply to the assembly level.
            - list of defaults here: https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/attributes/global
            - custom attributes can also be aplied.
            - Invalid attributes will throw a c# compiler exception
        #>
      [string[]]
      $AssemblyAttributes,


      <# List of assembly attributes to apply to the class.
            - Any valid c# class attribute can be applied
            - Invalid attributes will throw a c# compiler exception
        #>
      [string[]]
      $ClassAttributes,
        

      <#
         Override the default C# class template.
            - BinWips Tokens (a character sequence such as beginning with {# and ending with #}) can be included
               and will be replaced with the matching token either from defaults or the -Tokens paramter.
            - If a BinWips exists with out a matching value in -Tokens an exception is thrown.
            - Example: In the default template there is namespace '{#PSNameSpace#} {...}' when compiled
               {#PSNamespace#} is replaced with PSBinary to produce namesapce PSBinary {...}
        #>
      [string]
      $ClassTemplate,

      
      <#
            Override the default C# attribute template.
            BinWips Tokens are not supported.

            Example Template:

               using System;
               namespace BinWips {
                  [AttributeUsage(AttributeTargets.Assembly)]
                  public class BinWipsAttribute : Attribute {
                     public string Version { get; set; }
                     public BinWipsAttribute() { }
                     public BinWipsAttribute(string version) { Version = version; }
                  }
               }
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

      <#
        List of .NET assemblies for the host .exe to reference. These references will not be accessible from within the powershell script.
      #>
      [string[]]
      $HostReferences,

      <# List of files to include with the app. I.e., `-Resources "MyFirstResource.txt", "MySecondResource.txt"`

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

      # The platform to target, valid options include Linux and Windows
      [string]
      [ValidateSet('Linux', 'Windows')]
      $Platform,

      # The architecture to target, valid options include x86, x64, and arm64
      [string]
      [ValidateSet('x86', 'x64', 'arm64')]
      $Architecture,

      # Additional parameters to pass to the bflat compiler
      [string[]]
      $ExtraArguments,

      <#
        Which edition of PowerShell to target:
         - Core: PowerShell Core (pwsh)
         - Desktop: Windows PowerShell (powershell.exe)

        If not specified, defaults to the edition of PowerShell that is running the cmdlet.
        So if this function is run from pwsh, it will default to PowerShell Core.
        If this function is run from powershell.exe, it will default to Windows PowerShell.

        PowerShellEdition='Desktop' is only supported on Windows PowerShell 5.1 and newer. 
        If you try to use  PowerShellEdition='Desktop' and Platform='Linux', an error will be thrown. 
      #>
      [string]
      [ValidateSet('Core', 'Desktop')]
      $PowerShellEdition = $(Get-PSEdition)
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
         This function handles steps 1 and 2, then passes off work to Build-Bflat
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
      $target = "exe"
      $outExt = "exe"

      # If the user wants to cross-compile to linux but runs the cmdlet from Windows PowerShell, we nede to change the PowerShellEdition to Core
      # use can override this behavior by specifying -PowerShellEdition
      if ($Platform -eq 'Linux' -and $PowerShellEdition -eq 'Desktop' -and !$PSBoundParameters.ContainsKey('PowerShellEdition'))
      {
         $PowerShellEdition = 'Core'
      }

      if ($PowerShellEdition -eq 'Desktop' -and $Platform -eq 'Linux')
      {
         throw "PowerShellEdition='Desktop' is only supported when Platform='Windows'"
      }

      # Warn if both -Namespace and -Tokens are specified and tokens contains Namespace
      if ($PSBoundParameters.ContainsKey('Namespace') -and $null -ne $Tokens -and $Tokens.ContainsKey('Namespace'))
      {
         Write-Warning "Both -Namespace was specified and -Tokens, containing a value for Namespace. The value passed via -Tokens will be ignored."
      }

      # Warn if both -ClassName and -Tokens are specified and tokens contains ClassName
      if ($PSBoundParameters.ContainsKey('ClassName') -and $null -ne $Tokens -and $Tokens.ContainsKey('ClassName'))
      {
         Write-Warning "Both -ClassName was specified and -Tokens, containing a value for ClassName. The value passed via -Tokens will be ignored."
      }

      if ($ClassName -eq $Namespace)
      {
         throw "ClassName cannot be equal to Namespace"
      }
      
      $currentDir = (Get-Location).Path
      if (!$hasOutDir -and $hasOutFile)
      {
         $absoluteOutFile = [System.IO.Path]::GetFullPath($OutFile)
         $OutDir = [System.IO.Path]::GetDirectoryName($absoluteOutFile)
         # Make out dir if it doesn't exist
         New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
      }
      elseif (!$hasOutDir){
         $OutDir = $currentDir
      }

      # Validate out dir
      if (!(Test-Path $OutDir))
      {
         throw "Output directory does not exist: $OutDir"
      }
      elseif ($null -eq $OutDir -or $OutDir -eq "")
      {
         throw "Output directory cannot be null or empty"
      }


      if (!$hasScratchDir)
      {
         $ScratchDir = "$currentDir/.binwips"
      } 
      elseif ($null -eq $ScratchDir -or $ScratchDir -eq "")
      {
         throw "Scratch directory cannot be null or empty"
      }
 

      if (!$hasOutFile)
      {
         if ($inline)
         {
            $OutFile = "$OutDir/PSBinary.$outExt"
         }
         elseif ($multipleFiles)
         {
            #$OutFile = #$InFile[-1].Replace(".ps1", ".$outExt")
            $OutFile = [System.IO.Path]::ChangeExtension($InFile[-1], $outExt)
         }
         else
         {
            #$OutFile = $InFile.Replace(".ps1", ".$outExt")
            $OutFile = [System.IO.Path]::ChangeExtension($InFile, $outExt)
         }
      } # otherwise if path isn't absolute, make it absolute to out dir
      elseif ([System.IO.Path]::IsPathRooted($OutFile) -eq $false)
      {
         $OutFile = Join-Path $OutDir $OutFile
      }  
 

      if (!$hasClassTemplate -and $Library)
      {
         $ClassTemplate = Get-Content -Raw "$PSScriptRoot/../files/LibraryClassTemplate.cs"
      }
      elseif (!$hasClassTemplate)
      {
         $ClassTemplate = Get-Content -Raw "$PSScriptRoot/../files/ClassTemplate.cs"
      }
      if (!$hasAttributesTemplate)
      {
         $AttributesTemplate = Get-Content -Raw "$PSScriptRoot/../files/AttributesTemplate.cs"
      }

      if ($inline)
      {
         $psScript = $ScriptBlock.ToString()
      }
      else
      { 
         # read in content from each input file and merge them into 1 string
         $psScript = $InFile | ForEach-Object { Get-Content -Raw $_ } | Out-String
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
      elseif (!$PSBoundParameters.ContainsKey('Platform'))
      {
         throw "Unsupported platform"
      }

      if (!$PSBoundParameters.ContainsKey('Architecture'))
      {
         $Architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
      }

      if ($PSCmdlet.ShouldProcess('Create Scratch Directory'))
      {
         New-Item -ItemType Directory -Path $ScratchDir -Force | Out-Null
        
      }
      if ($PSCmdlet.ShouldProcess('Create Output Directory'))
      {
         New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
      }

      # Download Bflat if needed
      Get-BinWipsBFlat


      $funcArgs = @{
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
         CscArgumentList    = $ExtraArguments
         OutDir             = $OutDir
         ScratchDir         = $ScratchDir
         Force              = $Force
         Resources          = $Resources
         NoEmbedResources   = $NoEmbedResources
         Platform           = $Platform
         Architecture       = $Architecture
         References         = $HostReferences
         PowerShellEdition  = $PowerShellEdition
      }     

      Build-Bflat @funcArgs
      
   }
   End
   {
   }
}