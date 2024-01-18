function Get-BinWipsBFlat
{
    [CmdletBinding()]
    param()

    $platform = "windows"
    $arch = "x64"
    $archiveType = "zip"

    
    if ($IsLinux)
    {
     
        $platform = "linux-glibc"
        $archiveType = "tar.gz"
    }

     
    $moduleRoot =  Split-Path -Path $PSScriptRoot -Parent
    # Locate the compiler
    if ($null -ne (Get-Command "bflat" -ErrorAction SilentlyContinue) ) 
    { 
        Write-Verbose "Found bflat on path"
        return
    }
    elseif ($IsWindows)
    {
        $dotNetPath = "$moduleRoot/files/bflat/$platform/bflat.exe"
    }
    else
    {
        $dotNetPath = "$moduleRoot/files/bflat/$platform/bflat"
    }
    if (Test-Path $dotNetPath)
    {
        Write-Verbose "Found bflat at $dotNetPath"
        return
    }
 

    $path = "$moduleRoot/files/bflat/$platform"
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    

    # Check if the latest release is already downloaded
    Write-Verbose "BFlat not found, downloading from github"

    $apiUrl = "https://api.github.com/repos/bflattened/bflat/releases/latest"       
    $response = Invoke-RestMethod -Uri $apiUrl

    $asset = $response.assets | Where-Object { $_.name -like "*-$platform-$arch.$archiveType" }
    $url = $asset.browser_download_url

    $downloadPath = Join-Path $path "bflat.$archiveType"
    Write-Verbose "Downloading $url to $downloadPath"
    Invoke-WebRequest -Uri $url -OutFile $downloadPath
 
    if ($archiveType -eq "zip")
    {
        Expand-Archive -Path $downloadPath -DestinationPath $path
    }
    else
    {
        tar -xzf $downloadPath -C $path
    }

    Write-Verbose "Bflat installed at $path"


}