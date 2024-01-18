function Write-BinWipsExe
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
   [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
   [Alias()]
   [OutputType([int])]
   Param
   (
      # The powershell command to convert into a program
      # cannot be combined with `InFile`
      [Parameter(Mandatory = $true,
         ValueFromPipelineByPropertyName = $true,
         Position = 0)]
      $Script,


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

      # Directory to place output in, defaults to current directory
      # Dir will be created if it doesn't already exist. 
      [string]
      $OutDir,

      # Change the directory where work will be done defaults to 'obj' folder in current directory
      # Use -Clean to clean this directory before building
      # Dir will be created if it doesn't already exist. 
      [string]
      $ScratchDir,

      # Clean the scratch directory after building
      [switch]
      $Cleanup,

      # Overrite -OutFile if it already exists
      [switch]
      $Force, 


      [string]
      $CompilerPath,

      [string[]]
      $CompilerArgs
   )

   process
   {

      $hasClassAttributes = $PSBoundParameters.ContainsKey('ClassAttributes')
      $hasAssemblyAttributes = $PSBoundParameters.ContainsKey('AssemblyAttributes')
      $runtimeSetupScript = Get-Content -Raw "$PSScriptRoot\..\files\Setup-Runtime.ps1"
   
      $runtimeSetupScript = $runtimeSetupScript | Set-BinWipsToken -Key AssemblyPath -Value ($OutFile.TrimStart('.')) -Required 
   
      if ($Tokens)
      {
         $Tokens.GetEnumerator() | ForEach-Object {
            $runtimeSetupScript = $runtimeSetupScript | Set-BinWipsToken -Key $_.Key -Value $_.Value 
         } 
      }
   
      Write-Verbose $runtimeSetupScript
      if($PSCmdlet.ShouldProcess('Create Runtime Setup Script')) {
         $runtimeSetupScript | Out-File "$ScratchDir\Setup-Runtime.ps1" -Encoding unicode -Force:$Force
      }
      $encodedRuntimeSetup = [Convert]::ToBase64String(([System.Text.Encoding]::Unicode.GetBytes($runtimeSetupScript)))
    
   
      # 3. Base64 encode script for easy handling (no dealing with quotes)
      # https://stackoverflow.com/questions/15414678/how-to-decode-a-base64-string
      $encodedScript = [Convert]::ToBase64String(([System.Text.Encoding]::Unicode.GetBytes($psScript)))
      
      # 4. Insert script and replace tokens in class template
      $funtionName = [System.IO.Path]::GetFileNameWithoutExtension($OutFile)
      $binWipsVersion = $MyInvocation.MyCommand.ScriptBlock.Module.Version
      $csProgram = $ClassTemplate | Set-BinWipsToken -Key Script -Value $encodedScript `
      | Set-BinWipsToken -Key RuntimeSetup -Value $encodedRuntimeSetup -Required `
      | Set-BinWipsToken -Key ClassName -Value $ClassName -Required `
      | Set-BinWipsToken -Key Namespace -Value $Namespace -Required `
      | Set-BinWipsToken -Key BinWipsVersion -Value $binWipsVersion
      | Set-BinWipsToken -Key FunctionName -Value $funtionName
   
   
      
      if ($hasAssemblyAttributes)
      {
         # TODO: preformat assembly attributes
         Write-Verbose "Applying Assembly Attribuytes"
         $att = ""
         $AssemblyAttributes | ForEach-Object {
            $att += "$_`r`n"
         }
         if ($att -eq $null)
         {
            Write-Error "Failed to build assembly attributes"
         }
         $csProgram = $csProgram | Set-BinWipsToken -Key AssemblyAttributes -Value $att
      }
      else
      {
         $csProgram = $csProgram | Remove-BinWipsToken -Key AssemblyAttributes
      }
   
      if ($hasClassAttributes)
      {
         Write-Verbose "Applying class attributes"
         $att = ""
         $ClassAttributes | ForEach-Object {
            $att += "$_`r`n"
         }
         if ($att -eq $null)
         {
            Write-Error "Failed to build class attributes"
         }
         $csProgram = $csProgram | Set-BinWipsToken -Key ClassAttributes -Value $att
      }
      else
      {
         $csProgram = $csProgram | Remove-BinWipsToken -Key ClassAttributes
      }
      if ($Tokens)
      {
         $Tokens.GetEnumerator() | ForEach-Object {
            $csProgram = $csProgram | Set-BinWipsToken -Key $_.Key -Value $_.Value 
         } 
      }
   
   
      # 5. Output class + additional files to .cs files in scratch dir
      Write-Verbose "Writing to $ScratchDir"
      if($PSCmdlet.ShouldProcess('Create C# Source File')){
         $csProgram | Out-File "$ScratchDir/PSBinary.cs" -Encoding unicode -Force:$Force
      }
      if($PSCmdlet.ShouldProcess('Create BinWiPS Attribute File')){
         $attributesTemplate | Out-File "$ScratchDir/BinWipsAttr.cs" -Encoding unicode -Force:$Force
      }
     
   
   
      
      $buildCmd = "$CompilerPath $CompilerArgs"
      Write-Verbose $buildCmd
      if ($PSCmdlet.ShouldProcess('Create Binary'))
      {
         #$results = Invoke-Expression $buildCmd

         # Use [System.Diagnostics.Process]::Start() and redirect input to avoid Invoke-Expression
         $psi = [System.Diagnostics.ProcessStartInfo]::new($CompilerPath)
         
         $CompilerArgs | ForEach-Object {
            $psi.ArgumentList.Add($_)
         }
 
 
  


         $psi.RedirectStandardOutput = $true
         $psi.RedirectStandardError = $true
         $process = [System.Diagnostics.Process]::Start($psi)
         $process.WaitForExit()
         $results = @($process.StandardOutput.ReadToEnd(), $process.StandardError.ReadToEnd())
         
         if ($results -like '*Error*')
         {
           throw $results
         }
         elseif ($null -ne $results)
         {
            Write-Output $results
         }
      }
      else
      {
         Write-Verbose "Not building because ShouldProcess is false"
         return
      }
     
   
      # 7.
      if ($Cleanup)
      {
         Remove-Item $ScratchDir -Recurse
      }
      
   }
 
}