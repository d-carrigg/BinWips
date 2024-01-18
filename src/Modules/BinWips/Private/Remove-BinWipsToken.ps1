function Remove-BinWipsToken {
    
        <#
    .SYNOPSIS
        Remove all instances of -Key from source.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification='This function does not change state, it only removes text from a string')]
    param (
        # String to replace content from
        [parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [string] $Source,

        # Key of the BinWips token to replace 
        [parameter(Mandatory=$true, Position=1)]
        [string] $Key
    )
    
    begin {
        
    }
    
    process {
       $x =  $Source.Replace("{#$Key#}", "")
       return $x
    }
    
    end {
        
    }
}