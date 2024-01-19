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

    It 'Given a script file, should create a .exe that runs the script' {
        New-BinWips -InFile "$PSScriptRoot\files\HelloWorld.ps1" -ScratchDir $script:scratchDir -OutFile $script:outFile

        $script:outFile | Should -Exist
        $result = & $script:outFile
        $result | Should -Be "Hello World"

    }

    It 'Given multiple files, should produce a single exe' -Tag "MultiFile" {
        New-BinWips -InFile "$PSScriptRoot/files/MultiFile1.ps1", "$PSScriptRoot/files/MultiFile2.ps1"  -ScratchDir $script:scratchDir -OutFile $script:outFile

        $script:outFile | Should -Exist
        $result = & $script:outFile
        $result | Should -Be "Shared-Function from MutliFile1.ps1"
    }

    
    It 'Given a PowerShellEdition, should use that edition' -Tag "PowerShellEdition" {
        New-BinWips -ScriptBlock { Write-Host "Hello World" } -ScratchDir $script:scratchDir -OutFile $script:outFile -PowerShellEdition Desktop

        # read the PSBinary.exe and make sure it contains "powershell.exe"
        $script:outFile | Should -Exist
        $contents = Get-Content "$script:scratchDir/PSBinary.cs" -Raw
        $contents | Should -BeLike "*powershell.exe*"
    }

    It 'Given a script block with parameters, should accept the valid parameters' {
        New-BinWips -ScriptBlock { param($foo) Write-Output "$foo" } -ScratchDir $script:scratchDir -OutFile $script:outFile

        $script:outFile | Should -Exist
        $result = & $script:outFile "bar"
        $result | Should -Be "bar"
    }

    It 'Given named parameters, should accept the named parameters' -Tag "Named Params" {
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

    It 'Given a switch parameter, should work correctly' -Tag "Switches" { 
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

    It 'Given a script block parameter, should work correctkly' -Tag "ScriptBlockParameters" {
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

    It 'Given a hash table parameter, should work correctly' -Tag "HashTableParameters" {
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
        $result = & $script:outFile -baz '@{foo="bar"}'
        $result | Should -Be "Baz['foo'] = bar"
    }

    It 'Given an array parameter, should work correctly' -Tag "ArrayParameters" {
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
        $result = & $script:outFile -baz "foo","bar"
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
        
        $pwshPath = (get-command pwsh).Source
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

}