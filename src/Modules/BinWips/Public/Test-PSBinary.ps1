function Test-PSBinary {
    <#
    .SYNOPSIS
        Check if an assembly was built with BinWips.
    .EXAMPLE
        PS C:\> Test-PSBinary PSBinary.exe
    #>
    [CmdletBinding()]
    param (
        # Path to the assembly (either .dll or .exe)
        [Parameter(Mandatory=$true, Position=0)]
        [string]
        $Path
    )
    
    begin {
        
    }
    
    process {
        if(!(Test-Path $Path)){
            throw "'$Path' was not found or you do not have access."
        }
        
        # We gotta do some trickery to safely load this file
        # https://stackoverflow.com/questions/3832351/disposing-assembly
        # https://www.powershellmagazine.com/2014/03/17/pstip-reading-file-content-as-a-byte-array/
        $Path = Resolve-Path $Path
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        $asm = [System.Reflection.Assembly]::Load($bytes)

        # The binary is a BinWips binary if any of the attributes are the BinWipsAttribute
        # we know this since that attribute is added by default to the assembly
        # if it's not there no dice, no way for us to detect if it was made by BinWips		
        $attrItems = $asm.GetCustomAttributes($false)
        foreach($attr in $attrItems) {
            if($attr.TypeId.Name -eq 'BinWipsAttribute'){
                return $true
            }
        }
        return $false
    }
    
    end {
        
    }
}