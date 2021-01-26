# BinWips

:construction: Warning: This repository is still under construction, see the [TODO List](#TODO-List) at the bottom to make sure the features you want are complete​

Binary Written in PowerShell. Convert `.ps1` files to executables with sensible defaults. You can use the built in parameters to customize output to the fullest extent. Including complete control over the generated `.cs`, `.exe` files and any additional resources.  You can also generate .NET libraries (`.dll`s) which can be consumed by other .NET applications. Compilation targets include any valid platform for `.NET` application including `x86`,`x64` and MSIL (`Any CPU`).  In addition, you can target different .NET releases and reference external assemblies. 

## Getting Started

Install the module with:

```powershell
Install-Module BinWips
```

Create a simple program from an inline script block:

```powershell
New-PsBinary -ScriptBlock {echo "Hello World!"}
```

This will generate a program named `PSBinary.exe` in the current directory. Confirm everything worked by running:

```powershell
.\PSBinary.exe
```

You should see the following output:

```text
Hello World!
```

You can also generate programs from script files:

```powershell
New-PsBinary -InFile "path/to/myScript.ps1"
```

An executable will be generated in the current directory with the name `myScript.exe`. If you want to produce a library (`dll`) instead you can do so by using the `-Library` parameter:

```PowerShell
New-PsBinary -InFile "path/to/myScript.ps1" -Library
```

## Parameters

BinWips assemblies (both `exe`s and `dll`s) can accept arguments from the caller but parameters need to be entered a bit differently for BinWips to support them. To generate an exe that supports parameters use the `-Parameters` parameter. E.g

```powershell
# Note the escaped variable `$myParam
New-PSBinary -ScriptBlock {"Param was `$myParam"} -Parameters 'param($myParam)' 
# or 
New-PSBinary -InFile "MyScript.ps1" -Parameters 'param($myParam)'  # make sure not to include the param statment in your scipt
```

  If you generate a `.exe` the arguments work the same as they would if you wrote a script. E.g.

```bash
.\PSBinary.exe -String1 "Some Text" -ScriptBlock "{Write-Host 'Inception'}" -Switch1 -Array "Arrays?","Of Course"
```

Libraries look a little different than you might except coming from C#, but they just take a `param string[] args` parameter similar to the Main method of a c# program. The `param` modifier is supplied in case no parameters are passed. Calling in C# would look like

```c#
// both of these work, note the escaping of special chars (",') where neccessary
object result = PSBinary.Invoke("-String 1 'Some Text'", "-ScriptBlock \"{Write-Host 'Inception'}\"", "-Switch1 -Array \"Arrays?\",\"Of Course\"");
object result = PSBinary.Invoke("-String1 \"Some Text\" -ScriptBlock \"{Write-Host 'Inception'}\" -Switch1 -Array \"Arrays?\",\"Of Course\")";
```

**TODO: Fill in how to set parameters**



## Libraries



**TODO fill in**

## Including Resources with your Application

If you want to package additional files with your application you can uses the `-Resources` parameter. A resource can be any file (images, other `exe`s, `dll`s, etc) and are embedded in the generated .exe by default. In other words, the module will still generate a single file regardless of the number of resources you include.

To include additional files, pass an array of file paths to the `-Resources` parameter. For example, if you want to include 3 files:

1. MyImage.png - located in the same directory as the script
2. MyText.txt - located at c:\foo\MyText.txt
3. MyRequiredLibrary.dll - located at c:\Windows\ImportantFolder\MyRequiredLibrary.dll

you would use the following syntax:

```powershell
New-PSBinary -File MyScript.ps1 -Resources @(
    '.\MyImage.png',
    'c:\foo\MyText.txt',
    'c:\Windows\ImportantFolder\MyRequiredLibrary.dll'
)
```

The files must both exist and you must have access to said files otherwise BinWips will throw a terminating error. All files will be read in and embedded to the `.exe`. To use the resources in your script use the following syntax:

```powershell
$myImageContent = Get-PSBinaryResource ".\MyImage.png"
$myTextContent = Get-PSBinaryResource "c:\foo\MyText.txt"
$myDll = Get-PSBinaryResource "c:\Windows\ImportantFolder\MyRequiredLibrary.dll"
```

A few important notes:

- When you get a binary resource your are getting it’s content, not a path to a file, and not a `File` object. You can use the `-AsFile` parameter if you need a file reference, in which case the embedded resource will be written to a temp file (this is slower as content needs to first be written to disk).
- You can’t use `Get-Content` or `Get-Item` cmdlets with these  files because they do not exist as files when deployed

If you want to deploy the resources next to the `exe` instead of embedding them, include the `-NoEmbedResources` option. In which case the files will be copied to the `-OutDir` if they do not already exist at that location. If all resources are in the same directory as the script, or they already exist on the machine you want to deploy to. You don’t need to include them as resources, you can just access them as you normally would in your PowerShell script.

## Check if an application is a BinWips executable

Built in functionality is provided for checking if an assembly (`exe` or `dll`) was built with BinWips via the `Test-PSBinary` command:

```powershell
Test-PSBinary PSBinary.exe
```

 If you don’t have the BinWips module installed on a machine you can use the following:

```powershell
$Path = 'Path to assembly in question'
# We gotta do some trickery to safely load this file
# https://stackoverflow.com/questions/3832351/disposing-assembly
# https://www.powershellmagazine.com/2014/03/17/pstip-reading-file-content-as-a-byte-array/
$Path = Resolve-Path $Path
$bytes = [System.IO.File]::ReadAllBytes($Path)
$asm = [System.Reflection.Assembly]::Load($bytes)
$attrItems = $asm.GetCustomAttributes($false)
foreach($attr in $attrItems) {
  if($attr.TypeId.Name -eq 'BinWipsAttribute'){
     Write-Host "Assembly is a BinWips executeable"
	}
}
```

## Advanced Usage

You can fully customize the generated output by replacing the class template and you can run additional preprocessing before the compiler is invoked. If the built in customization options don't meet your needs this section will guide you through full customization of the compiled output. This section requires knowledge of C#. Additionally, unless you include the default BinWips attribute in your attributes/class template you will not be able to detect your application as a BinWips application (how-to is included in this section). 

**TODO fill in**

## TODO List

Order doesn’t matter.

- [x] Basic Executeable
- [x] Assembly Attributes
- [x] ClassAttributes
- [x] Multiple scripts support
- [ ] Parameters
- [x] Different Template for Libraries
- [ ] Allow Method Name Modification for libraries
- [x] Attributes Template Parameter
- [x] CSC Argument List
- [ ] Identify C# Compiler Errors (catch them)
- [ ] Newer C# compiler
- [ ] Newer PowerShell SDK version
- [ ] Linux support (anything special needed)?
- [ ] Interactive apps (investigate if anything special needs to be done to support adding user input at runtime)
  - [ ] It does, need to redirect the PS host input to console input, will this require me to implement a fully custom PS host?
- [ ] Clean
- [ ] Docs Section on how binwips works
- [ ] KeepScratchDir
- [ ] Force
- [x] Resources
- [x] Get-PSBinaryResource
- [ ] BinWips PS Provider
- [ ] `-AsFile` parameter for Get-PsBinaryResource which auto extracts to a temp dir and returns a file info object
- [ ] NoEmbedResources
- [ ] More Tests (and switch to pester)
- [ ] PlattyPS (or PSPlatty I forget) for documentation
- [ ] Finish Documentation
- [ ] Finish ReadMe

## Limitations

There are some things that cannot be accomplished by the BinWips module.

1. Anything from the TODO List that is unchecked won’t work.
2. Second, you should be aware of any security risks for the .NET Framework version you target
3. BinWips encodes scripts as Base64 strings (and the default class template decodes those strings into plain text before adding them to the runspace) and I believe this helps prevent against sanitization issues, but I haven’t fully tested this. I think this is primarily only a concern if you have a script which creates an `.exe` based on user generated content but I felt it worth sharing.
4. I do not yet recommend using BinWips for production and/or critical environments because of the reasons listed above. 

I plan to fix all of the above limitations as much as possible. 

## Inspiration and References

The following links either provided inspiration for this module or are stack overflow links. There are a few non-stack overflow links but regardless I want to credit the authors. This is just a general list but you'll find some of the same links within the source code if you choose to visit that section of this repository.

- https://gallery.technet.microsoft.com/scriptcenter/PS2EXE-GUI-Convert-e7cb69d5
- https://stackoverflow.com/questions/15414678/how-to-decode-a-base64-string
- [-resource (C# Compiler Options) | Microsoft Docs](https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/compiler-options/resource-compiler-option)
- [.net - How to read embedded resource text file - Stack Overflow](https://stackoverflow.com/questions/3314140/how-to-read-embedded-resource-text-file)
- [c# - List all embedded resources in a folder - Stack Overflow](https://stackoverflow.com/questions/8208289/list-all-embedded-resources-in-a-folder)
- [#PSTip Reading file content as a byte array – PowerShell Magazine](https://www.powershellmagazine.com/2014/03/17/pstip-reading-file-content-as-a-byte-array/)
- [c# - Disposing assembly - Stack Overflow](https://stackoverflow.com/questions/3832351/disposing-assembly)
- [How to Create a Console Shell - PowerShell | Microsoft Docs](https://docs.microsoft.com/en-us/powershell/scripting/developer/prog-guide/how-to-create-a-console-shell?view=powershell-7.1)

