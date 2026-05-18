$ErrorActionPreference = "Stop"

$BaselineUrl = "https://raw.githubusercontent.com/r4kk0/windows-scrubber/main/tweaks/baseline.ps1"
$HelpersUrl = "https://raw.githubusercontent.com/r4kk0/windows-scrubber/main/lib/helpers.ps1"
$DownloadRoot = Join-Path $env:TEMP "windows-scrubber"
$TweaksRoot = Join-Path $DownloadRoot "tweaks"
$LibRoot = Join-Path $DownloadRoot "lib"
$BaselinePath = Join-Path $TweaksRoot "baseline.ps1"
$HelpersPath = Join-Path $LibRoot "helpers.ps1"

Write-Host "Windows Scrubber launcher"
Write-Host "Baseline URL: $BaselineUrl"
Write-Host "Helpers URL: $HelpersUrl"
Write-Host "Baseline path: $BaselinePath"
Write-Host "Helpers path: $HelpersPath"

try {
    foreach ($folder in @($DownloadRoot, $TweaksRoot, $LibRoot)) {
        if (-not (Test-Path $folder)) {
            Write-Host "Creating folder: $folder"
            New-Item -Path $folder -ItemType Directory -Force | Out-Null
        }
    }

    Write-Host "Setting process execution policy bypass..."
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

    Write-Host "Downloading baseline script..."
    Invoke-WebRequest -Uri $BaselineUrl -OutFile $BaselinePath -UseBasicParsing -ErrorAction Stop

    if (-not (Test-Path $BaselinePath)) {
        Write-Error "Download did not create the expected baseline script: $BaselinePath"
        exit 1
    }

    Write-Host "Downloading helper script..."
    Invoke-WebRequest -Uri $HelpersUrl -OutFile $HelpersPath -UseBasicParsing -ErrorAction Stop

    if (-not (Test-Path $HelpersPath)) {
        Write-Error "Download did not create the expected helper script: $HelpersPath"
        exit 1
    }

    Write-Host "Running baseline script..."
    & $BaselinePath
} catch {
    Write-Error "Windows Scrubber launcher failed: $($_.Exception.Message)"
    exit 1
}
