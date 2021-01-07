# BinWips

Binary Written in PowerShell. Convert `.ps1` files to executables with sensible defaults. You can use the built in parameters to customize output to the fullest extent. Including complete control over the generated `.cs`, `.exe` files and any additional resources.  You can also generate .NET libraries (`.dll`s) which can be consumed by other .NET application. Compilation targets include any valid platform for `.NET` application including `x86`,`x64` and MSIL (`Any CPU`).  

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



## Including Resources with your Application

If you want to package additional files with your application you can uses the `-Resources` parameter. A resource can be any file (images, other `exe`s, `dll`s, etc) and are embedded in the generated .exe by default. In other words, the module will still generate a single file regardless of the number of resources you include.

To include additional files, pass an array of file paths to the `-Resources` parameter. For example, if you want to include 3 files:

1. MyImage.png - located in the same directory as the script
2. MyText.txt - located at c:\foo\MyText.txt
3. MyRequiredLibrary.dll - located at c:\Windows\ImportantFolder\MyRequiredLibrary.dll

you would use the following syntax:

```powershell
New-Binary -File MyScript.ps1 -Resources @(
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

- When you get a binary resource your are getting it’s content, not a path to a file, and not a `File` object. 
- You can’t use `Get-Content` or `Get-Item` cmdlets with these  files because they do not exist as files when deployed

If you want to deploy the resources next to the `exe` instead of embedding them, include the `-NoEmbedResources` option. In which case the files will be copied to the `-OutDir` if they do not already exist at that location. If all resources are in the same directory as the script, or they already exist on the machine you want to deploy to. You don’t need to include them as resources, you can just access them as you normally would in your PowerShell script.

## PowerShell Runtime Modifications

You can modify the session in which your script is run as an executable. This is useful if you have multiple scripts which you convert to `.exe`s and you want to run some common setup before executing each script. This includes things such as shared cmdlets, module imports, startup messages, and *almost* anything else you can run as a PowerShell script. At this time you cannot modify the PowerShell host (you can't say change the output color of text). To accomplish that you will need to see the [Advanced Usage Section](#advanced-usage) section. 

An example of a modification comes from the BinWips source code. In the default class template, the BinWips module adds the `Get-PSBinaryResource` cmdlet to the runspace. This is used if you include resources as described in the [Resources section](#including-resources-with-your-application).
**TODO fill in**



## Check if an application is a BinWips executable

Built in functionality is provided for checking if an assembly (`exe` or `dll`) was built with BinWips via the `Test-PSBinary` command:

```powershell
Test-PSBinary PSBinary.exe
```

 If you don’t have the BinWips module installed on a machine you can use the following:

```
$asm = 
```

## Advanced Usage

You can fully customize the generated output by replacing the class template and you can run additional preprocessing before the compiler is invoked. If the built in customization options don't meet your needs this section will guide you through full customization of the compiled output. This section requires knowledge of C#. Additionally, unless you include the default BinWips attribute in your attributes/class template you will not be able to detect your application as a BinWips application (how-to is included in this section). 

**TODO fill in**

## TODO List

- [ ] Assembly Attributes
- [ ] ClassAttributes
- [ ] Different Template for Libraries
- [ ] Allow Method Name Modification
- [ ] Attributes Template Parameter
- [ ] CSC Argument List
- [ ] PSRuntimeModifications
- [ ] Clean
- [ ] KeepScratchDir
- [ ] Force
- [ ] Resources
- [ ] NoEmbedResources
- [ ] More Tests
- [ ] Finish Documentation
- [ ] Finish ReadMe



## Limitations

**TODO**

## Inspiration and References

The following links either provided inspiration for this module or are stack overflow links. There are a few non-stackoverflow links but regardless I want to credit the authors. This is just a general list but you'll find some of the same links within the source code if you choose to visit that section of this repository.

- https://gallery.technet.microsoft.com/scriptcenter/PS2EXE-GUI-Convert-e7cb69d5
- https://stackoverflow.com/questions/15414678/how-to-decode-a-base64-string
