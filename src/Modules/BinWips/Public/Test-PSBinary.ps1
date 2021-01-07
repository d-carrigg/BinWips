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
        $Path = Resolve-Path $Path
        $asm = [System.Reflection.Assembly]::LoadFile($Path)
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