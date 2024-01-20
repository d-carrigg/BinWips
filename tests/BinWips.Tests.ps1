BeforeAll {
    $path = Resolve-Path "$PSScriptRoot/../src/Modules/BinWips"
    Import-Module -Name $path -Force

    $script:scratchDir = Join-Path $PSScriptRoot ".binwips"
    $script:outFile = Join-Path $PSScriptRoot "PSBinary.exe"
}



Describe 'New-BinWips' {
    
    AfterEach {
        # Cleanup
        Remove-Item -Path $script:outFile -ErrorAction SilentlyContinue
        Remove-Item $script:scratchDir -Recurse -ErrorAction SilentlyContinue
    }

    It 'Given a script block, should create a .exe that runs the script block' -Tag 'Basic' {
        
        New-BinWips -ScriptBlock { Write-Host "Hello World" } -ScratchDir $script:scratchDir -OutFile $script:outFile

        $script:outFile | Should -Exist
        $result = & $script:outFile
        $result | Should -Be "Hello World" 

    }

    It 'Given a script block with -OutFile, should use the -OutFile name' -Tag "Basic" {

        New-BinWips -ScriptBlock { Write-Host "Hello World" } -ScratchDir $script:scratchDir -OutFile "ThisIsATestExeFromBinWipsTests.exe"

        "ThisIsATestExeFromBinWipsTests.exe" | Should -Exist
        $result = & "$(pwd)/ThisIsATestExeFromBinWipsTests.exe"
        $result | Should -Be "Hello World" 

        # remove the special file
        Remove-Item "ThisIsATestExeFromBinWipsTests.exe" -ErrorAction SilentlyContinue
    }

    It 'Given a script file, should create a .exe that runs the script' -Tag "InFile" {
        New-BinWips -InFile "$PSScriptRoot\files\HelloWorld.ps1" -ScratchDir $script:scratchDir -OutFile $script:outFile

        $script:outFile | Should -Exist
        $result = & $script:outFile
        $result | Should -Be "Hello World"

    }

    It 'Given a script file with -OutFile, should use the -OutFile name' -Tag "Basic" {

        New-BinWips -InFile "$PSScriptRoot\files\HelloWorld.ps1" -ScratchDir $script:scratchDir -OutFile "ThisIsATestExeFromBinWipsTests.exe"

        "ThisIsATestExeFromBinWipsTests.exe" | Should -Exist
        $result = & "$(pwd)/ThisIsATestExeFromBinWipsTests.exe"
        $result | Should -Be "Hello World" 

        # remove the special file
        Remove-Item "ThisIsATestExeFromBinWipsTests.exe" -ErrorAction SilentlyContinue
    }

    It 'Given multiple files, should produce a single exe' -Tag "InFile", "MultiFile" {
        New-BinWips -InFile "$PSScriptRoot/files/MultiFile1.ps1", "$PSScriptRoot/files/MultiFile2.ps1"  -ScratchDir $script:scratchDir -OutFile $script:outFile

        $script:outFile | Should -Exist
        $result = & $script:outFile
        $result | Should -Be "Shared-Function from MutliFile1.ps1"
    }

    It 'Given a script file with -OutFile, should use the -OutFile name' -Tag "Basic" {

        New-BinWips -InFile "$PSScriptRoot/files/MultiFile1.ps1", "$PSScriptRoot/files/MultiFile2.ps1" `
                -ScratchDir $script:scratchDir `
                -OutFile "ThisIsATestExeFromBinWipsTests.exe"

        "ThisIsATestExeFromBinWipsTests.exe" | Should -Exist
        $result = & "$(pwd)/ThisIsATestExeFromBinWipsTests.exe"
        $result | Should -Be "Shared-Function from MutliFile1.ps1"

        # remove the special file
        Remove-Item "ThisIsATestExeFromBinWipsTests.exe" -ErrorAction SilentlyContinue
    }

    
    It 'Given an invalid path for -InFile, should throw' -Tag  "InFile", "InvalidInFile" {
        { 
            New-BinWips -InFile "kajhgkjadfhlkjashdf" -ScratchDir $script:scratchDir -OutFile $script:outFile 
        } | Should -Throw -ExpectedMessage "Error: kajhgkjadfhlkjashdf could not be found or you do not have access"

    }

    
    It 'Given a PowerShellEdition, should use that edition' -Tag "PowerShellEdition" {
        New-BinWips -ScriptBlock { Write-Host "Hello World" } -ScratchDir $script:scratchDir -OutFile $script:outFile -PowerShellEdition Desktop

        # read the PSBinary.exe and make sure it contains "powershell.exe"
        $script:outFile | Should -Exist
        $contents = Get-Content "$script:scratchDir/PSBinary.cs" -Raw
        $contents | Should -BeLike "*ProcessStartInfo(@`"powershell.exe`")*"
    }

    It 'When running on windows powershell, targeting Linux, correctly uses core edition when not explicity set' -Tag "PowerShellEdition" {

        Mock -ModuleName BinWips Get-PSEdition { return "Desktop" } 
        

        New-BinWips -ScriptBlock { Write-Output "Hello World" } -Platform Linux `
            -ScratchDir $script:scratchDir -OutFile $script:outFile 

        $content = Get-Content $script:scratchDir/PSBinary.cs -Raw
        $content | Should -BeLike "*ProcessStartInfo(@`"pwsh`")*"
    
    }

    It 'Throws an exception when Target=Linux and PowerShellEdition=Desktop' -Tag "PowerShellEdition" {
        { 
            New-BinWips -ScriptBlock { Write-Output "Hello World" } -Platform Linux `
                -ScratchDir $script:scratchDir -OutFile $script:outFile -PowerShellEdition Desktop
        } | Should -Throw -ExpectedMessage "PowerShellEdition='Desktop' is only supported when Platform='Windows'"
    }

    It 'Given a script block with parameters, should accept the valid parameters'  -Tag "Parameters" {
        New-BinWips -ScriptBlock { param($foo) Write-Output "$foo" } -ScratchDir $script:scratchDir -OutFile $script:outFile

        $script:outFile | Should -Exist
        $result = & $script:outFile "bar"
        $result | Should -Be "bar"
    }

    It 'Given named parameters, should accept the named parameters' -Tag  "Parameters" , "Named Parameters" {
        $sb = {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory = $true)]
                [string]$foo,
                $baz
            )
            Write-Output "$foo"
        }
        New-BinWips -ScriptBlock $sb -ScratchDir $script:scratchDir -OutFile $script:outFile

        $script:outFile | Should -Exist
        $result = & $script:outFile -foo "bar"
        $result | Should -Be "bar"
    }

    It 'Given a switch parameter, should pass in a switch parameter that can be treated as a true/false value' -Tag  "Parameters", "Switches" { 
        $sb = {
            [CmdletBinding()]
            param(
                [switch]$baz
            )
            if ($baz)
            {
                Write-Output "Switch was true"
            }
        }
        New-BinWips -ScriptBlock $sb -ScratchDir $script:scratchDir -OutFile $script:outFile
        $script:outFile | Should -Exist
        $result = & $script:outFile -baz
        $result | Should -Be "Switch was true"
    }

    It 'Given a script block parameter, should allow passing in a script block that can be executed' -Tag "Parameters", "ScriptBlockParameters" {
        $sb = {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory = $true)]
                [scriptblock]$baz
            )
            & $baz
        }
        New-BinWips -ScriptBlock $sb -ScratchDir $script:scratchDir -OutFile $script:outFile
        $script:outFile | Should -Exist
        $result = & $script:outFile -baz "{ Write-Host 'Hello World' }"
        $result | Should -Be "Hello World"
    }

    It 'Given a hash table parameter, correctly create a hashtable that can be keyed into' -Tag "Parameters", "HashTableParameters" {
        $sb = {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory = $true)]
                [hashtable]$baz
            )
            Write-Host "Baz['foo'] = $($baz['foo'])"
        }
        New-BinWips -ScriptBlock $sb -ScratchDir $script:scratchDir -OutFile $script:outFile
        $script:outFile | Should -Exist
        if ($IsWindows)
        {
            $result = & $script:outFile -baz '@{foo="bar"}'
        }
        else
        {
            $result = & $script:outFile -baz '@{foo=\"bar\"}'
        }
        
        $result | Should -Be "Baz['foo'] = bar"
    }

    It 'Given an array parameter, should correctly create an array that can be indexed into' -Tag "Parameters", "ArrayParameters" {
        $sb = {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory = $true)]
                [array]$baz
            )
            Write-Host "Baz[0] = $($baz[0]), Baz[1] = $($baz[1])"
        }
        New-BinWips -ScriptBlock $sb -ScratchDir $script:scratchDir -OutFile $script:outFile
        $script:outFile | Should -Exist
        $result = & $script:outFile -baz "foo", "bar"
        $result | Should -Be "Baz[0] = foo, Baz[1] = bar"
    }

    It 'Given resources, should embed those resources and make them accessible in the script' -Tag "Resources" {
        $sb = {
            $content = Get-BinWipsResource "EmbeddedResource.txt"
            Write-Host $content
        }
        New-BinWips -ScriptBlock $sb -ScratchDir $script:scratchDir -OutFile $script:outFile -Resources @('tests/files/EmbeddedResource.txt')
        $script:outFile | Should -Exist
        $result = & $script:outFile -baz
        $result | Should -Be "This is an embedded resource."
    }

    It 'Given a custom class name, should use that class name' -Tag "CustomClassName" {
        $sb = {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory = $true)]
                [string]$foo
            )
            Write-Output "$foo"
        }
        New-BinWips -ScriptBlock $sb -ScratchDir $script:scratchDir -OutFile $script:outFile -ClassName "MyClass"
        $script:outFile | Should -Exist
        $csContent = Get-Content $script:scratchDir/PSBinary.cs -Raw
        $csContent | Should -BeLike "*class MyClass*"
    }

    It 'Given a custom namespace, should use that namespace' -Tag "CustomNamespace" {
        $sb = {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory = $true)]
                [string]$foo
            )
            Write-Output "$foo"
        }
        New-BinWips -ScriptBlock $sb -ScratchDir $script:scratchDir -OutFile $script:outFile -Namespace "MyNamespace"
        $script:outFile | Should -Exist
        $csContent = Get-Content $script:scratchDir/PSBinary.cs -Raw
        $csContent | Should -BeLike "*namespace MyNamespace*"
    }

    It 'Given a custom class template, uses that template' -Tag "ClassTemplate" { 
        $sb = {
            throw "Should not be called"
        }  
        $classTemplate = @"
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

        New-BinWips -ScriptBlock $sb -ClassTemplate $classTemplate -ScratchDir $script:scratchDir `
            -OutFile $script:outFile
        $script:outFile | Should -Exist
        
        $script:outFile | Should -Exist
        $result = & $script:outFile -baz
        $result | Should -Be "Ignore Script"
    }

    It 'Given an Invalid class template, correctly displays compiler errors' -Tag "ClassTemplate", "InvalidClassTemplate" {
        $sb = {
            throw "Should not be called"
        }  
        $classTemplate = @"
        // use tokens to replace values in the template, see -Tokens for more info
        namespace {#Namespace#} {
           public class MyClass {
              public static void Main(string[] args) {
                var x = "{#RuntimeSetip#}"; // ignored but required to be in template
                var y = "{#Script#}"; // ignored but required to be in template
                Console.WriteLine(x) // syntax error, missing ;
              }
           }
        }
"@
        { New-BinWips -ScriptBlock $sb -ScratchDir $script:scratchDir -OutFile $script:outFile `
                -ClassTemplate $classTemplate
        } | Should -Throw -ExpectedMessage "*error CS1002: ; expected*"
    }


    It 'Should reference required dlls when supplied' -Tag "References" {
        $sb = {
            Write-Host "It Worked"
        }  
        $classTemplate = @"
        using Newtonsoft.Json;
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
        
        $pwshPath = (Get-Command pwsh).Source
        $pwshFolder = Split-Path $pwshPath -Parent
        $newtonsoftPath = Join-Path $pwshFolder "Newtonsoft.Json.dll"
        
        New-BinWips -ScriptBlock $sb -ScratchDir $script:scratchDir -OutFile $script:outFile `
            -ClassTemplate $classTemplate `
            -HostReferences @($newtonsoftPath)
        
        # So Long as the program compiles and runs, we're golden
        $script:outFile | Should -Exist
        $result = & $script:outFile
        $result | Should -Be "Ignore Script"
    }

    It 'Adds program output when -Verbose is passed in' -Tag "Debugging" {
        $sb = {
            Write-Host "It Worked"
        }  
        
        New-BinWips -ScriptBlock $sb -ScratchDir $script:scratchDir -OutFile $script:outFile 
        $funcName = [System.IO.Path]::GetFileNameWithoutExtension($script:outFile)
        $script:outFile | Should -Exist
        $result = & $script:outFile -Verbose

        # Will only be printed if -Verbose is passed in
        $result | Should -Contain "Call Command: $funcName -Verbose"
    }
}