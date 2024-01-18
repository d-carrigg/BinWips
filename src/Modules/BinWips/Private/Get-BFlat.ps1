function Get-BFlat
{
    [CmdletBinding()]
    param()

    if ($IsWindows)
    {
        $dotNetPath = where.exe bflat.exe
    }
    else
    {
        $dotNetPath = which bflat
    }
    # Locate the compiler
    if ([string]::IsNullOrWhiteSpace($dotNetPath) -eq $false -and $dotNetPath -ne "INFO: Could not find files for the given pattern(s).")
    {
        Write-Verbose "Found bflat at $dotNetPath"
        return
    }
    elseif ($IsWindows)
    {
        $dotNetPath = Resolve-Path "$PSScriptRoot\..\files\bflat\windows\bflat.exe"
    }
    else
    {
        $dotNetPath = Resolve-Path "$PSScriptRoot\..\files\bflat\linux\bflat"
    }
    if(Test-Path $dotNetPath){
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

    $path = "$PSScriptRoot\..\files\bflat\$platform"
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