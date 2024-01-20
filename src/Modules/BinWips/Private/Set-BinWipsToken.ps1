function Set-BinWipsToken
{
    <#
    .SYNOPSIS
        Replaces all instances of -Key with -Value in -Source string
    .DESCRIPTION
        Long description
    .EXAMPLE
        PS C:\> <example usage>
        Explanation of what the example does
    .INPUTS
        Inputs (if any)
    .OUTPUTS
        Output (if any)
    .NOTES
        General notes
    #>
    [cmdletbinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification='This function does not change state, it only removes text from a string')]
    param (
        # String to replace content from
        [parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [string] $Source,

        # Key of the BinWips token to replace 
        [parameter(Mandatory=$true, Position=1)]
        [string] $Key,

        # The value to substitue for -Key
        [parameter(Mandatory=$false, Position=2)]
        [string] $Value,

        # Error out if the token is not present
        [Parameter()]
        [switch]
        $Required
    )
    process {
        if($Required -and ($null -eq $Value)){
            throw "Required property not inclued for key $Key"
        } elseif(($null -eq $Value) -and (!$Required))
        {
            write-warning "Value for BinWipsToken: $Key was null so it will be removed. To throw an error, use the -Required paramter."
            $Value = " "
        }
        
        Write-Verbose "Replacing $key with $value"
        return ($source.Replace("{#$key#}", $value))
    }
   
}
