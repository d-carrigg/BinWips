function Set-PSBinaryToken
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
    param (
        # String to replace content from
        [parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [string] $Source,

        # Key of the BinWips token to replace 
        [parameter(Mandatory=$true, Position=1)]
        [string] $Key,

        # The value to substitue for -Key
        [parameter(Mandatory=$true, Position=2)]
        [string] $Value,

        # Error out if the token is not present
        # TODO: Make this parameter work
        [Parameter()]
        [switch]
        $Required
    )
    
    Write-Host "Replacing $key with $value"
    # TODO: Make regex and use that to prevent accidental replacements (allow escape sequences)
    return ($source.Replace("{#$key#}", $value))
}