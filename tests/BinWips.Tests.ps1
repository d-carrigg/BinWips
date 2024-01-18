BeforeAll {
    $path = Resolve-Path "$PSScriptRoot/../src/Modules/BinWips"
    Import-Module -Name $path -Force

    $script:scratchDir = Join-Path $PSScriptRoot ".binwips"
    $script:outFile = Join-Path $PSScriptRoot "PSBinary.exe"
}


AfterAll {
    # Cleanup
    #Remove-Item -Path $script:outFile -ErrorAction SilentlyContinue
   # Remove-Item $script:scratchDir -Recurse -ErrorAction SilentlyContinue
}


Describe 'New-BinWips' {


    It 'Given a script block, should create a .exe that runs the script block' -Tag 'Basic' {
        
        New-BinWips -ScriptBlock { Write-Host "Hello World" } -ScratchDir $script:scratchDir -OutFile $script:outFile -Verbose

        $script:outFile | Should -Exist
        $result = & $script:outFile
        $result | Should -Be "Hello World" 

    }

    It 'Given a script file, should create a .exe that runs the script'   {
        New-BinWips -InFile "$PSScriptRoot\files\HelloWorld.ps1" -ScratchDir $script:scratchDir -OutFile $script:outFile

        $script:outFile | Should -Exist
        $result = & $script:outFile
        $result | Should -Be "Hello World"

    }

    It 'Given a script block with parameters, should accept the valid parameters' {
        New-BinWips -ScriptBlock { param($foo) Write-Output "$foo" } -ScratchDir $script:scratchDir -OutFile $script:outFile

        $script:outFile | Should -Exist
        $result = & $script:outFile "bar"
        $result | Should -Be "bar"
    }

    It 'Given named parameters, should accept the named parameters' -Tag "Named Params"  {
        $sb = {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory=$true)]
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
            if($baz){
                Write-Output "Switch was true"
            }
        }
        New-BinWips -ScriptBlock $sb -ScratchDir $script:scratchDir -OutFile $script:outFile
        $script:outFile | Should -Exist
        $result = & $script:outFile -baz
        $result | Should -Be "Switch was true"
    }

   It 'Given resources, should embed those resources and make them accessible in the script' -Tag "Resources" {
    $sb = {
        $content =  Get-BinWipsResource "EmbeddedResource.txt"
        write-host $content
    }
    New-BinWips -ScriptBlock $sb -ScratchDir $script:scratchDir -OutFile $script:outFile -Resources @('tests/files/EmbeddedResource.txt')
    $script:outFile | Should -Exist
    $result = & $script:outFile -baz
    $result | Should -Be "This is an embedded resource."
   }

   It 'Given'
}