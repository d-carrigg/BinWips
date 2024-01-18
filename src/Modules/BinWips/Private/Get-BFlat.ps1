function Get-BFlat
{
    [CmdletBinding()]
    param()

     
    $moduleRoot = Split-Path( Split-Path -Path $PSScriptRoot -Parent) -Parent
    # Locate the compiler
    if ($null -ne (Get-Command "bflat" -ErrorAction SilentlyContinue) ) 
    { 
        Write-Verbose "Found bflat on path"
        return
    }
    elseif ($IsWindows)
    {
        $dotNetPath = "$moduleRoot/files/bflat/windows/bflat.exe"
    }
    else
    {
        $dotNetPath = "$moduleRoot/files/bflat/linux/bflat"
    }
    if (Test-Path $dotNetPath)
    {
        Write-Verbose "Found bflat at $dotNetPath"
        return
    }
 

    $platform = "windows"
    $arch = "x64"
    $archiveType = "zip"

    
    if ($IsLinux)
    {
     
        $platform = "linux-glibc"
        $archiveType = "tar.gz"
    }

    $path = " $moduleRoot/files/bflat/$platform"
    [System.IO.Directory]::CreateDirectory($path) | Out-Null

    # Check if the latest release is already downloaded
    Write-Verbose "Downloading Bflat from github"

    $apiUrl = "https://api.github.com/repos/bflattened/bflat/releases/latest"       
    $response = Invoke-RestMethod -Uri $apiUrl

    $asset = $response.assets | Where-Object { $_.name -like "*-$platform-$arch.$archiveType" }
    $url = $asset.browser_download_url

    $downloadPath = Join-Path $path "bflat.$archiveType"
    $outPath = Join-Path $path "bflat"
    Invoke-WebRequest -Uri $url -OutFile $downloadPath 

    if ($archiveType -eq "zip")
    {
        Expand-Archive -Path $downloadPath -DestinationPath $path
    }
    else
    {
        tar -xzf $downloadPath -C $path
    }

    Write-Verbose "Bflat downloaded to $outPath"


}