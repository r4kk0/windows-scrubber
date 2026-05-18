param(
    [switch]$Core,
    [switch]$Gaming,
    [switch]$Repair,
    [switch]$StressTest,
    [switch]$Dev,
    [switch]$All
)

$ErrorActionPreference = "Stop"

function Show-Usage {
    Write-Host "Usage: .\install-apps.ps1 [-Core] [-Gaming] [-Repair] [-StressTest] [-Dev] [-All]"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\install-apps.ps1 -Core"
    Write-Host "  .\install-apps.ps1 -Core -Dev"
    Write-Host "  .\install-apps.ps1 -All"
}

function Show-Menu {
    Write-Host "Select app group to install:"
    Write-Host "  1. Core Apps"
    Write-Host "  2. Gaming / Launchers"
    Write-Host "  3. Repair Utilities"
    Write-Host "  4. Stress Test / Benchmark Tools"
    Write-Host "  5. Dev Tools"
    Write-Host "  6. Everything"
    Write-Host "  Q. Quit"
}

$requestedGroups = @()

if ($All) {
    $requestedGroups = @("Core", "Gaming", "Repair", "StressTest", "Dev")
} else {
    if ($Core) { $requestedGroups += "Core" }
    if ($Gaming) { $requestedGroups += "Gaming" }
    if ($Repair) { $requestedGroups += "Repair" }
    if ($StressTest) { $requestedGroups += "StressTest" }
    if ($Dev) { $requestedGroups += "Dev" }
}

if ($requestedGroups.Count -eq 0) {
    Show-Menu
    $selection = Read-Host "Enter selection"

    switch ($selection) {
        "1" { $requestedGroups = @("Core") }
        "2" { $requestedGroups = @("Gaming") }
        "3" { $requestedGroups = @("Repair") }
        "4" { $requestedGroups = @("StressTest") }
        "5" { $requestedGroups = @("Dev") }
        "6" { $requestedGroups = @("Core", "Gaming", "Repair", "StressTest", "Dev") }
        "Q" { Write-Host "No apps selected. Exiting."; exit 0 }
        "q" { Write-Host "No apps selected. Exiting."; exit 0 }
        default {
            Write-Host "Invalid selection. No apps will be installed."
            exit 0
        }
    }
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget was not found. Install or enable winget before running this script."
    exit 1
}

$appsPath = Join-Path $PSScriptRoot "..\data\apps.json"

if (-not (Test-Path $appsPath)) {
    Write-Error "App data file was not found: $appsPath"
    exit 1
}

$appGroups = Get-Content $appsPath -Raw | ConvertFrom-Json
$successes = @()
$failures = @()

foreach ($groupName in $requestedGroups) {
    $apps = $appGroups.$groupName

    if (-not $apps) {
        Write-Warning "Skipping missing app group: $groupName"
        continue
    }

    Write-Host ""
    Write-Host "Installing $groupName apps..."

    foreach ($app in $apps) {
        Write-Host "Installing $($app.name) [$($app.id)]..."

        try {
            & winget install --id $app.id --exact --accept-source-agreements --accept-package-agreements --silent

            if ($LASTEXITCODE -eq 0) {
                Write-Host "Installed $($app.name)."
                $successes += [pscustomobject]@{
                    Group = $groupName
                    Name = $app.name
                    Id = $app.id
                }
            } else {
                Write-Warning "Failed to install $($app.name). winget exited with code $LASTEXITCODE."
                $failures += [pscustomobject]@{
                    Group = $groupName
                    Name = $app.name
                    Id = $app.id
                    Reason = "winget exit code $LASTEXITCODE"
                }
            }
        } catch {
            Write-Warning "Failed to install $($app.name): $($_.Exception.Message)"
            $failures += [pscustomobject]@{
                Group = $groupName
                Name = $app.name
                Id = $app.id
                Reason = $_.Exception.Message
            }
        }
    }
}

Write-Host ""
Write-Host "Install summary"
Write-Host "---------------"
Write-Host "Successful: $($successes.Count)"
Write-Host "Failed:     $($failures.Count)"

if ($successes.Count -gt 0) {
    Write-Host ""
    Write-Host "Successful installs:"
    foreach ($item in $successes) {
        Write-Host "  [$($item.Group)] $($item.Name) ($($item.Id))"
    }
}

if ($failures.Count -gt 0) {
    Write-Host ""
    Write-Host "Failed installs:"
    foreach ($item in $failures) {
        Write-Host "  [$($item.Group)] $($item.Name) ($($item.Id)) - $($item.Reason)"
    }
}
