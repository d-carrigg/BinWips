# BinWips: Binary Written in PowerShell

Create .NET applications from PowerShell scripts and inline code blocks with
control over the generated `.cs` and `.exe` files and any additional resources.
Build for linux and windows on x86, x64, and arm64 architectures.

```powershell
New-BinWips -ScriptBlock {echo "Hello World!"} -OutFile "HelloWorld.exe"
.\HelloWorld.exe
# Hello World!
```

## Getting Started

Install the module with:

```powershell
Install-Module BinWips -AllowPrerelease
Import-Module BinWips
```

> Note: BinWips uses [bflat](https://github.com/bflattened/bflat). This is a
> dependency of the module and will be downloaded (one time) automatically if
> not detected in the path.

Create a simple program from an inline script block to create a program with the
default name `PSBinary.exe`:

```powershell
New-BinWips -ScriptBlock {echo "Hello World!"}

# Run: ./PSBinary.exe
# Output:
# Hello World!
```

Interactive programs are supported:

```powershell
New-BinWips -ScriptBlock {
    $name = Read-Host "What is your name?"
    echo "Hello $name!"
}

# Output:
# What is your name?: BinWips
# Hello BinWips!
```

As well as, programs that take parameters (simple and complex):

```powershell
New-BinWips -ScriptBlock {
    param(
        $myParam,

        [int]
        $MyIntParam,

        [switch]
        $MySwitchParam,

        [ValidateSet("Option1", "Option2")]
        [Parameter()]
        $MyValidateSetParam
    )
    echo "Param was $myParam"
}

# Run: ./PSBinary.exe -myParam "Hello World!"
# Output:
# Param was Hello World!
```

> :spiral_notepad: If you call a BinWips program from a powershell session, you
> will need to wrap powershell objects in quotes. For example, if you want to
> pass in a hash table: `.\PSBinary.exe -HashTable '@{MyVal=1;OtherVal=2}'`.
> This is because PowerShell will create the object, then convert it into a
> string using `.ToString()`, which in this case would be the string literal
> `System.Collections.Hashtable`, not the actual hash table. This limitation
> does not apply to calling from another shell (bash, cmd, etc).

You can also generate programs from script files. The files will be loaded in
the order they are passed in. The last filename will be used as the name of the
generated program. For example, if you have two files `myScript.ps1` and
`myOtherScript.ps1` and you want to generate a program called `myScript.exe` you
would run:

```powershell
New-BinWips -InFile "path/to/myOtherScript.ps1", "path/to/myScript.ps1"

# Run: ./myScript.exe
```

You can always override the name of the generated program with the `-OutFile`
parameter.

> :spiral_notepad: Note: By default BinWips compiles to the platform and
> architecture of the machine it is run on. You can override this behavior with
> the `-Platform` and `-Architecture` parameters. See the
> [Parameters](#Parameters) section for more information.

When generating a program from a script file, the script file can take
parameters as well, if you pass in multiple script files, the program parameters
are generated from the first script file.

Parameter validation works, tab completion does not. BinWips automatically adds
support for getting help on the generated program by using
`.\PSBinary.exe help`.

```text
NAME
    PSBinary

SYNTAX
    PSBinary [-SomeParam] <string> [<CommonParameters>]

PARAMETERS
    -SomeParam <string>
        Description for SomeParam
```

### Other examples

Some other examples of BinWips programs you can create:

```powershell
# Creates a program that shows a window on Windows x64.
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

```

## Parameters

Detailed help for this module is included via the `Get-Help` cmdlet. Run
`Get-Help New-BinWips -Detailed` for more information. Examples are included in
the help. You can also check out the
[/tests/BinWips.Tests.ps1](/tests/BinWips.Tests.ps1) file for examples of how to
use the module.

```text
SYNTAX
    New-BinWips [-ScriptBlock] <Object> [-OutDir <String>] [-ScratchDir <String>] [-OutFile <String>] [-Cleanup] [-Namespace <String>] [-ClassName <Object>] [-AssemblyAttributes <String[]>] [-ClassAttributes <String[]>] [-ClassTemplate <String>]
    [-AttributesTemplate <String>] [-Tokens <Hashtable>] [-Resources <String[]>] [-NoEmbedResources] [-Platform <String>] [-Architecture <String>] [-ExtraArguments <String[]>] [-WhatIf] [-Confirm] [<CommonParameters>]

    New-BinWips [-InFile] <String[]> [-OutDir <String>] [-ScratchDir <String>] [-OutFile <String>] [-Cleanup] [-Namespace <String>] [-ClassName <Object>] [-AssemblyAttributes <String[]>] [-ClassAttributes <String[]>] [-ClassTemplate <String>]
    [-AttributesTemplate <String>] [-Tokens <Hashtable>] [-Resources <String[]>] [-NoEmbedResources] [-Platform <String>] [-Architecture <String>] [-ExtraArguments <String[]>] [-WhatIf] [-Confirm] [<CommonParameters>]
PARAMETERS
    -ScriptBlock <Object>
        The powershell command to convert into a program
        cannot be combined with `InFile`

    -InFile <String[]>
        Source Script file(s), order is important
        Files added in order entered
        Exe name is defaulted to last file in array

    -OutDir <String>
        Directory to place output in, defaults to current directory
        Dir will be created if it doesn't already exist.

    -ScratchDir <String>
        Change the directory where work will be done defaults to 'obj' folder in current directory
        Use -Clean to clean this directory before building
        Dir will be created if it doesn't already exist.

    -OutFile <String>
        Name of the .exe to generate. Defaults to the -InFile (replaced with .exe) or
        PSBinary.exe if a script block is inlined

    -Cleanup [<SwitchParameter>]
        Clean the scratch directory before building
        As compared to -KeepScratchDir which removes scratch dir *after* build.

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

    -AssemblyAttributes <String[]>
        List of assembly attributes to apply to the assembly level.
                    - list of defaults here: https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/attributes/global
                    - custom attributes can also be aplied.
                    - Invalid attributes will throw a c# compiler exception

    -ClassAttributes <String[]>
        List of assembly attributes to apply to the class.
                    - Any valid c# class attribute can be applied
                    - Invalid attributes will throw a c# compiler exception

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

    -HostReferences <String[]>
        List of .NET assemblies for the host .exe to reference. These references will not be accessible from within the powershell script.

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

    -Platform <String>
        The platform to target

    -Architecture <String>
        The architecture to target

    -ExtraArguments <String[]>
        Additional parameters to pass to the bflat compiler

    -PowerShellEdition <String>
        Which edition of PowerShell to target:
         - Core: PowerShell Core (pwsh)
         - Desktop: Windows PowerShell (powershell.exe)

        If not specified, defaults to the edition of PowerShell that is running the cmdlet.
        So if this function is run from pwsh, it will default to PowerShell Core.
        If this function is run from powershell.exe, it will default to Windows PowerShell.

        PowerShellEdition='Desktop' is only supported on Windows PowerShell 5.1 and newer.
        If you try to use  PowerShellEdition='Desktop' and Platform='Linux', an error will be thrown.

    -WhatIf [<SwitchParameter>]

    -Confirm [<SwitchParameter>]

    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https://go.microsoft.com/fwlink/?LinkID=113216).
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
knowledge of C#.

### Class Tempalates

When BinWips generates a .NET program it uses a class template to setup a new
powershell instance and run your scripts. You pass in a custom template as a
string using `-ClassTemplate` parameter. BinWips supports tokens in the class
template which are replaced with values at runtime. Tokens are strings which
begin with `{#` and end with `#}`. To override the BinWips version you could
pass in `-Tokens @{BinWipsVersion='1.0.0'}`. See the below example
`-ClassTemplate` for basic usage. This template would generate a console
program.

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

### Tokens

BinWips uses tokens in the format of `{#TokenName#}` to replace values in the
class template. The following tokens are replaced by default. Any tokens marked
as required must be included in the class template or an exception will be
thrown.

| Token Name      | Required | Description                                                                                 |
| --------------- | -------- | ------------------------------------------------------------------------------------------- |
| BinWipsVersion  | Yes      | The version of BinWips used to generate the program                                         |
| Script          | Yes      | The script to run, encoded as a base64 string                                               |
| RuntimeSetup    | Yes      | The runtime setup script, encoded as a base64 string                                        |
| ClassName       | Yes      | The name of the class to generate                                                           |
| Namespace       | Yes      | The namespace to use                                                                        |
| BinWipsVersion  | No       | The version of BinWips used to generate the program                                         |
| FunctionName    | No       | The name of the function to display when showing help documentation                         |
| BinWipsPipeGuid | No       | The guid used to identify the pipe between the generated program and the powershell process |

When creating a custom class template you can use any of the above tokens. You
can also define additional tokens, enabling template reuse.

## References

If you're C# class template needs to reference other assemblies you can use the
`-HostReferences` parameter. This parameter takes an array of strings which are
paths to assemblies to reference. For example, if you want to reference
`Newtonsoft.Json.dll` you would use the following syntax:

```powershell
New-BinWips -InFile "MyScript.ps1" -HostReferences "C:\Path\To\Newtonsoft.Json.dll"
```

BinWips will throw an error if the assembly does not exist or if you do not have
a matching reference for each assembly you reference in your class template.

## Contributing

Contributions are welcome, please open an issue or pull request. A couple of
general requirements:

- Must pass PSScriptAnalyzer with severity of `warning` or greater
- Add Pester tests for any new features, see the workflow file for how the
  pipeline runs the tests

## Testing

Testing is done through Pester. To run the tests, clone the repo and run

```powershell
Invoke-Pester -Script ./tests/BinWips.Tests.ps1

<#
Tags: Basic, MultiFile, Named Params, Switches, ScriptBlockParameters, ClassTemplate, CustomNamespace, CustomClassName, Resources
#>
```

## Installing from source

To install from the source code (not recommended):

```powershell
git clone https://github.com/d-carrigg/BinWips.git
Import-Module ./BinWips/src/Modules/BinWips
```

## Troubleshoting

### Error: DllNotFound_Linux, objwriter, objwriter.so

This error can occur if libc++-dev is not installed. To install it run:

```bash
sudo apt install libc++-dev
```

## TODO List

Order not important.

- [ ] Ability to package modules with the exe (Each Function is a verb so
      `Verb-Noun` becomes `exe_name verb parameters`)
- [ ] Help and Verison # Support (--help and --version or a verb/something along
      those lines)
  - [x] Help
  - [ ] Version

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
