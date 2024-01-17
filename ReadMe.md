# BinWips: Binary Written in PowerShell

Create .NET applications and libraries from PowerShell scripts and inline code
blocks with control over the generated `.cs`, `.exe`, and `.dll` files and any additional resources. Target linux and windows on x86, x64, and arm64.

## Getting Started

Install the module with:

```powershell
# TODO: Publish so this works: Install-Module BinWips
# For now, git clone the repo
Install-Module /gitrepo/src/Modules/BinWips
```

Create a simple program from an inline script block:

```powershell
New-BinWips -ScriptBlock {echo "Hello World!"}
```

This will generate a program named `PSBinary.exe` in the current directory.
Confirm everything worked by running:

```powershell
.\PSBinary.exe
```

You should see the following output:

```text
Hello World!
```

You can also generate programs from script files:

```powershell
New-BinWips -InFile "path/to/myScript.ps1"
```

An executable will be generated in the current directory with the name
`myScript.exe`. 

## Parameters

BinWips assemblies (both `exe`s and `dll`s) can accept arguments from the
caller.

```powershell
# Note the escaped variable `$myParam
New-BinWips -ScriptBlock {
    param($myParam)
    echo "Param was `$myParam"
}

# Also works with scripts
New-BinWips -InFile "MyScript.ps1"
## Content of MyScript.ps1
# param($myParam)
# echo "Param was $myParam"
```

If you generate a `.exe` the arguments work the same as they would if you wrote
a script. E.g.

```powershell
.\PSBinary.exe -String1 "Some Text" -ScriptBlock "{Write-Host 'Inception'}" -Switch1 -Array "Arrays?","Of Course"
```

Parameter validation works, tab completion does not. You can use `.\PSBinary.exe help` to get help. For your module. This will produce PowerShell style help for your program. No additional work is required on your part, this is done automatically.

```text
NAME
    PSBinary

SYNTAX
    PSBinary [-baz] [<CommonParameters>]


PARAMETERS
    -baz

    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https://go.microsoft.com/fwlink/?LinkID=113216).

REMARKS
    None
```

## All New-BinWips Parameters

Detailed help for this module is included via the `Get-Help` cmdlet. Run
`Get-Help New-BinWips -Detailed` for more information.

```
NAME
    New-BinWips

SYNOPSIS
    Creates a new PowerShell binary.


SYNTAX
    New-BinWips [-ScriptBlock] <Object> [-Namespace <String>] [-ClassName <Object>] [-OutFile <String>]
    [-AssemblyAttributes <String[]>] [-NoDefaultAttributes] [-ClassAttributes <Hashtable>] [-ClassTemplate <String>]
    [-AttributesTemplate <String>] [-Tokens <Hashtable>] [-CscArgumentList <String[]>] [-OutDir <String>] [-ScratchDir
    <String>] [-Clean] [-KeepScratchDir] [-Force] [-Resources <String[]>] [-NoEmbedResources] [-Library]
    [<CommonParameters>]

    New-BinWips [-InFile] <String[]> [-Namespace <String>] [-ClassName <Object>] [-OutFile <String>] [-AssemblyAttributes
    <String[]>] [-NoDefaultAttributes] [-ClassAttributes <Hashtable>] [-ClassTemplate <String>] [-AttributesTemplate
    <String>] [-Tokens <Hashtable>] [-CscArgumentList <String[]>] [-OutDir <String>] [-ScratchDir <String>] [-Clean]
    [-KeepScratchDir] [-Force] [-Resources <String[]>] [-NoEmbedResources] [-Library] [<CommonParameters>]


DESCRIPTION
    Generates a .EXE from a script.


PARAMETERS
    -ScriptBlock <Object>
        The powershell command to convert into a program
        cannot be combined with `InFile`

    -InFile <String[]>
        Source Script file(s), order is important
        Files added in order entered
        Exe name is defaulted to last file in array

    -Namespace <String>
        Namespace for the generated program.
        This parameter is trumped by -Tokens, so placing a value here will be overriden by
        whatever is in -Tokens
        So if you did -Namespace A -Tokens @{Namespace='B'} Namespace would be set to B not A
        Must be a valid C# namespace
        Defaults to PSBinary

    -ClassName <Object>
        Class name for the generated program
        This parameter is trumped by -Tokens, so placing a value here will be overriden
        by whatever is in -Tokens
        So if you did -ClassName A -Tokens @{ClassName='B'} ClassName would be set to B not A
        must be a valid c# class name and cannot be equal to -Namespace
        Defaults to Program

    -OutFile <String>
        Name of the .exe to generate. Defaults to the -InFile (replaced with .exe) or
        PSBinary.exe if a script block is inlined

    -AssemblyAttributes <String[]>
        Hashtable of assembly attributes to apply to the assembly level.
                    - list of defaults here:
        https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/attributes/global
                    - custom attributes can also be aplied.
                    - Invalid attributes will throw a c# compiler exception
                    - Attributes are applied in addition to the defaults unless -NoDefaultAttributes

    -NoDefaultAttributes [<SwitchParameter>]
        Exclude default attributes from being applied to PSBinary.
        Unless this is included some default attributes will be applied to the program.
        So that other scripts/programs can identify it as a BinWips.

    -ClassAttributes <Hashtable>
        Hashtable of assembly attributes to apply to the class.
                    - Any valid c# class attribute can be applied
                    - Invalid attributes will throw a c# compiler exception
                    - Attributes are applied in addition to the defaults unless -NoDefaultAttributes

    -ClassTemplate <String>
        Override the default class template.
        - BinWips Tokens (a character sequence such as beginning with {# and ending with #}) can be included
          and will be replaced with the matching token either from defaults or the -Tokens paramter.
        - If a BinWips exists with out a matching value in -Tokens an exception is thrown.
        - Example: In the default template there is namespace '{#PSNameSpace#} {...}' when compiled
          {#PSNamespace#} is replaced with PSBinary to produce namesapce PSBinary {...}

    -AttributesTemplate <String>
        Override the default attributes template.
        BinWips Tokens not supported.

    -Tokens <Hashtable>
        Hashtable of tokens to replace in the class template.
        Exclude the '{#' and '#}' in the keys.

        Example:
        -Tokens @{Namespace='CustomNamespace';ClassName='MyCoolClass'}

        Reserved Tokens
        ---------------
        {#Script#} The script content to compile

    -CscArgumentList <String[]>
        Additional C# Compiler parameters you want to pass (e.g. references)

    -OutDir <String>
        Directory to place output in, defaults to current directory
        Dir will be created if it doesn't already exist.

    -ScratchDir <String>
        Change the directory where work will be done defaults to '.binwips' folder in current directory
        Use -Clean to clean this directory after building
        Dir will be created if it doesn't already exist.

    -Clean [<SwitchParameter>]
        Clean the scratch directory before building
        As compared to -KeepScratchDir which removes scratch dir *after* build.

    -KeepScratchDir [<SwitchParameter>]
        After build don't remove the scratch dir.
        As compared to -Clean which removes all files in scratch dir *before* build.

    -Force [<SwitchParameter>]
        Overrite -OutFile if it already exists

    -Resources <String[]>
        List of files to include with the app
                    - If -NoEmbedResources is specified then files are embedded in the exe.
                       - Files are copied to out dir with exe if they don't already exist
                    - Else files must be referenced specially (see below)

                  To call files in script (if -NoEmbedresources is *not* included):
                  `$myFile = Get-PsBinaryResource FileName.ext`
                  where `FileName.ext` is the file you want to use.
                  This returns the content of the file, not a path to it.

                  Only use this if you want to package things like settings files
                  or images. Otherwise files are accessed normally by the generated exe.

    -NoEmbedResources [<SwitchParameter>]
        Don't embed any resource specifed by -Resources
        instead they are copied to out dir if they don't already exist

    -Library [<SwitchParameter>]
        Output to a .NET .dll instead of an .exe

    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https://go.microsoft.com/fwlink/?LinkID=113216).
```

## Libraries

If you want to produce a library (`dll`) instead you can do so
by using the `-Library` parameter:

```PowerShell
New-BinWips -InFile "path/to/myScript.ps1" -Library
```

Libraries look a little different than you might expect coming from C#, but they
just take a `param string[] args` parameter similar to the Main method of a c#
program. The `param` modifier is supplied in case no parameters are passed.
Calling in C# would look like

```c#

PSBinary.Invoke("-String 1 'Some Text'", "-ScriptBlock \"{Write-Host 'Inception'}\"", "-Switch1 -Array \"Arrays?\",\"Of Course\"");
```

## Embedding Resources

If you want to package additional files with your application you can uses the
`-Resources` parameter. A resource can be any file (images, other `exe`s,
`dll`s, etc) and are embedded in the generated .exe by default. In other words,
the module will still generate a single file regardless of the number of
resources you include.

To include additional files, pass an array of file paths to the `-Resources`
parameter. For example, if you want to include 3 files:

1. MyImage.png - located in the same directory as the script
2. MyText.txt - located at c:\foo\MyText.txt
3. MyRequiredLibrary.dll - located at
   c:\Windows\ImportantFolder\MyRequiredLibrary.dll

you would use the following syntax:

```powershell
New-BinWips -File MyScript.ps1 -Resources @(
    '.\MyImage.png',
    'c:\foo\MyText.txt',
    'c:\Windows\ImportantFolder\MyRequiredLibrary.dll'
)
```

The files must both exist and you must have access to said files otherwise
BinWips will throw a terminating error. All files will be read in and embedded
to the `.exe`. To use the resources in your script use the following syntax:

```powershell
$myImageContent = Get-PSBinaryResource "MyImage.png"
$myTextContent = Get-PSBinaryResource "MyText.txt"
$myDll = Get-PSBinaryResource "MyRequiredLibrary.dll"
```

A few important notes:

- The file names are case sensitive and do not include the path (filename only). 
  
- You can’t use `Get-Content` or `Get-Item` cmdlets with these files because
  they do not exist as files when deployed

If you want to deploy the resources next to the `exe` instead of embedding them,
include the `-NoEmbedResources` option. In which case the files will be copied
to the `-OutDir` if they do not already exist at that location. If all resources
are in the same directory as the script, or they already exist on the machine
you want to deploy to. You don’t need to include them as resources, you can just
access them as you normally would in your PowerShell script.

## Advanced Usage

You can fully customize the generated output by replacing the class template and
you can run additional preprocessing before the compiler is invoked. If the
built in customization options don't meet your needs this section will guide you
through full customization of the compiled output. This section requires
knowledge of C#. Additionally, unless you include the default BinWips attribute
in your attributes/class template you will not be able to detect your
application as a BinWips application (how-to is included in this section).

### Class Tempalates

When BinWips generates a .NET program it uses a class template to setup a new powershell instance and run your scripts. You pass in a custom template as a string using
`-ClassTemplate` parameter. BinWips supports tokens in the class template which
are replaced with values at runtime. Tokens are strings which begin with `{#`
and end with `#}`. To override the BinWips version you could pass in
`-Tokens @{BinWipsVersion='1.0.0'}`. See the below example `-ClassTemplate` for
basic usage. This template would generate a console program.

```c#
// Generaed by BinWips {#BinWipsVersion#}
using System;
using BinWips;
using System.Diagnostics;

// attributes which can be used to identify this assembly as a BinWips
// https://stackoverflow.com/questions/1936953/custom-assembly-attributes
[assembly: BinWips("{#BinWipsVersion#}")]
{#AssemblyAttributes#}
namespace {#Namespace#} {
         
    {#ClassAttributes#}
    class {#ClassName#} 
    {
        public static void Main(string[] args)
        {


            // script is inserted in base64 so we need to decode it
            var runtimeSetup = DecodeBase64("{#RuntimeSetup#}");
            var funcName = "{#FunctionName#}";

            var ending = "";
            if (args.Length == 1 && args[0] == "help")
            {
                ending = $"Get-Help -Detailed {funcName}";
            }
            else
            {
                ending = $"{funcName} {string.Join(" ", args)}";
            }

            var script = DecodeBase64("{#Script#}");
            var wrappedScript = $"{runtimeSetup}\n\n function {funcName}\n {{\n {script}\n }}\n{ending}";


            var encodedCommand = EncodeBase64(wrappedScript);

            // call PWSH to execute the script passing in the args
            var psi = new ProcessStartInfo(@"pwsh.exe");
            psi.Arguments = "-NoProfile -NoLogo -WindowStyle Hidden -EncodedCommand " + encodedCommand;
            //psi.RedirectStandardInput = true;
            var process = Process.Start(psi);
            process.EnableRaisingEvents = true;

            process.WaitForExit();

        }
        static string DecodeBase64(string encoded)
        {
            var decodedBytes = Convert.FromBase64String(encoded);
            var text = System.Text.Encoding.Unicode.GetString(decodedBytes);
            return text;
        }

        static string EncodeBase64(string text)
        {
            var bytes = System.Text.Encoding.Unicode.GetBytes(text);
            var encoded = Convert.ToBase64String(bytes);
            return encoded;
        }
    }
}
```

## Testing

Testing is done through Pester. To run the tests, clone the repo and run

```powershell
Invoke-Pester -Script ./tests/BinWips.Tests.ps1

<#
Tags: Named Params, Switches
#>
```

## TODO List

Order doesn’t matter.

- [x] Basic Executeable
- [x] Assembly Attributes
- [x] ClassAttributes
- [x] Multiple scripts support
- [x] Parameters
- [ ] Improve Params for Libraries if Possible (any way to strongly type the
      args? or params array at least?) -- source gen?
- [x] Different Template for Libraries
- [ ] Allow Method Name Modification for libraries
- [x] Attributes Template Parameter
- [x] CSC Argument List
- [ ] Identify C# Compiler Errors (catch them)
- [ ] Framework targeting
- [x] Linux support (anything special needed)?
- [x] Interactive apps (investigate if anything special needs to be done to
      support adding user input at runtime)
  - [ ] It does, need to redirect the PS host input to console input, will this
        require me to implement a fully custom PS host?
- [ ] Clean
- [ ] Docs Section on how binwips works
- [ ] KeepScratchDir
- [ ] Force
- [x] Resources
- [x] Get-PSBinaryResource
- [ ] BinWips PS Provider
- [x] More Tests (and switch to pester)
- [ ] Finish Documentation
- [ ] Finish ReadMe
- [ ] Ability to package modules with the exe (Each Function is a verb so `Verb-Noun` becomes `exe_name verb parameters`)
- [ ] Windows/GUIS
- [ ] Help and Verison # Support (--help and --version or a verb/something along those lines)
  - [x] Help
  - [ ] Version
- [ ] Is there a way to pass variables back to the host terminal? So if we 
      did something like -ErrorVariable or -OutVariable we could pass that back 
      if the host terminal was PWSH. Maybe a way with remoting (check if parent proc is pwsh, if so use remoting to pass back). 

## Limitations

There are some things that cannot be accomplished by the BinWips module.

1. See the [TODO List](#TODO-List) for a list of features that are not yet
   implemented
2. You should be aware of any security risks for the .NET Framework version you
   target
3. Assemblies are not signed so they are not tamper proof

## Inspiration and References

The following links either provided inspiration for this module or were used as
references when building it.

- https://gallery.technet.microsoft.com/scriptcenter/PS2EXE-GUI-Convert-e7cb69d5
- https://stackoverflow.com/questions/15414678/how-to-decode-a-base64-string
- [-resource (C# Compiler Options) | Microsoft Docs](https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/compiler-options/resource-compiler-option)
- [.net - How to read embedded resource text file - Stack Overflow](https://stackoverflow.com/questions/3314140/how-to-read-embedded-resource-text-file)
- [c# - List all embedded resources in a folder - Stack Overflow](https://stackoverflow.com/questions/8208289/list-all-embedded-resources-in-a-folder)
- [#PSTip Reading file content as a byte array – PowerShell Magazine](https://www.powershellmagazine.com/2014/03/17/pstip-reading-file-content-as-a-byte-array/)
- [c# - Disposing assembly - Stack Overflow](https://stackoverflow.com/questions/3832351/disposing-assembly)
- [How to Create a Console Shell - PowerShell | Microsoft Docs](https://docs.microsoft.com/en-us/powershell/scripting/developer/prog-guide/how-to-create-a-console-shell?view=powershell-7.1)
