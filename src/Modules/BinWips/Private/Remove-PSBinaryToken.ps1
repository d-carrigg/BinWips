function Remove-PSBinary {
    
        <#
    .SYNOPSIS
        Remove all instances of -Key from source.
    #>
    [CmdletBinding()]
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
       $x =  $Source.Replace($Key, "")
       return $x
    }
    
    end {
        
    }
}