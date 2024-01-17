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
    if($Required -and ($Value -eq $null)){
        throw "Required property not inclued for key $Key"
    } elseif(($Value -eq $null) -and (!$Required))
    {
        write-warning "Value for BinWipsToken: $Key was null so it will be removed. To throw an error, use the -Required paramter."
        $Value = " "
    }
    
    Write-Verbose "Replacing $key with $value"
    # TODO: Make regex and use that to prevent accidental replacements (allow escape sequences)
    return ($source.Replace("{#$key#}", $value))
}
