<#
    This script shows the basic proof of concept. 
    Takes an inline script ($psScript) and generates 
    a .exe that runs the script. Output is placed in 
    tests/inlineApp and includes
    - C# file with the script + helper content
    - Program (.exe) that runs the script
    - exe does not depend on the script file
#>

## HELPER FUNCTIONS
function Set-PSBinaryToken {
    # Replaces all instances of $key with $value in $source string
    [cmdletbinding()]
    param($source,$key,$value)
    Write-Host "Replacing $key with $value"
    return ($source.Replace("{#$key#}",$value))
}

## MAIN CODE
# C# Compiler
$cscPath = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"

# Templates which identify a BinWips app are applied here and included in compilation
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

# Default class template used to generate the C# class
$classTemplate =  @"
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
            var decodedBytes = Convert.FromBase64String("{#Script#}");
            var script = System.Text.Encoding.Unicode.GetString(decodedBytes);
           
            // build runspace and execute it
            // additional setup could be added 
            // by default we do an out string so that
            // console output looks nice 
            powerShell.AddScript(script)
                        .AddCommand("Out-String");
            var results = powerShell.Invoke();

            // output the results
            foreach(var result in results){
                Console.WriteLine(result);
            }
        }
    }
}
"@


# $psScript = @"
# "App Is Running"
# Get-Process | Out-GridView
# "@
$psScript = {Get-Process}

# Stop the escaping of quote marks, TODO: better sanitization
#$sanitizedScript = $psScript.Replace('"','""');

# I foud a better saniziation which is don't sanitize
$Bytes = [System.Text.Encoding]::Unicode.GetBytes($psScript)
$EncodedText =[Convert]::ToBase64String($Bytes)

# set replacements, starting with script content
$psBinary = Set-PSBinaryToken -source $classTemplate -key Script -value $EncodedText
$psBinary = Set-PSBinaryToken -source $psBinary -key BinWipsVersion -value "0.1"
$psBinary = Set-PSBinaryToken -source $psBinary -key Namespace -value "MyNamespace"
$psBinary = Set-PSBinaryToken -source $psBinary -key ClassName -value "Program"

# Compiler needs a .cs file to compiler
$psBinary | Out-File "PSBinary.cs" -Force
$attributesTemplate | Out-File "BinWipsAttr.cs" -Force

# Run the compiler
$cscArgs = @('-out:PSBinary.exe', '/reference:C:\Windows\assembly\GAC_MSIL\System.Management.Automation\1.0.0.0__31bf3856ad364e35\System.Management.Automation.dll', '/target:exe',
            'PSBinary.cs', 'BinWipsAttr.cs')

# Using $x for the & command below doesn't seem to work 
# (PS thinks it's a string or something)
# need to find a better way because i don't want to harcode the path
# Maybe just add the path needed earlier in the script to $env:Path?
#$x = "$dotNetPath $cscArgs"
& "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe" $cscArgs

# Run the program
#& ".\PSBinary.exe"