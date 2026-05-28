function Install-WingetApp {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppName,

        [Parameter(Mandatory = $true)]
        [string]$PackageId
    )

    Invoke-Tweak "Install $AppName" {
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            Write-Skip "winget was not found. $AppName will not be installed."
            return
        }

        $previousProgressPreference = $ProgressPreference
        $ProgressPreference = "SilentlyContinue"

        try {
            $wingetOutput = & winget install --id $PackageId --exact --accept-source-agreements --accept-package-agreements --silent --disable-interactivity 2>&1
        } finally {
            $ProgressPreference = $previousProgressPreference
        }

        $wingetExitCode = $LASTEXITCODE
        $wingetText = ($wingetOutput | Out-String).Trim()

        if ($wingetExitCode -eq 0) {
            Write-Host "PASS: $AppName install completed successfully."
        } elseif ($wingetText -match "already installed|No available upgrade found|No newer package versions are available") {
            Write-Host "INFO: $AppName is already installed and no newer package is available."
        } else {
            Write-Host "WARN: $AppName install exited with code $wingetExitCode."
            if ($wingetText -and ($wingetText.Length -le 400)) {
                Write-Host $wingetText
            }
        }
    }
}

function Install-AppList {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [object[]]$Apps,

        [switch]$SetChromeAsDefault
    )

    Write-ScrubberStage $Title

    foreach ($app in $Apps) {
        Install-WingetApp -AppName $app.Name -PackageId $app.Id
    }

    if ($SetChromeAsDefault) {
        Set-ChromeDefaults
    }
}

function Start-SteamAppInstall {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppName,

        [Parameter(Mandatory = $true)]
        [string]$SteamAppId
    )

    Invoke-Tweak "Open Steam install for $AppName" {
        $steamUri = "steam://install/$SteamAppId"

        try {
            Start-Process $steamUri
            Write-Host "INFO: Opened Steam install prompt for $AppName."
            Write-Host "INFO: Steam may require sign-in and user confirmation before downloading."
        } catch {
            Write-Host "WARN: Could not open Steam install prompt for ${AppName}: $($_.Exception.Message)"
        }
    }
}

function Get-WorkstationApps {
    return @(
        @{ Name = "Google Chrome"; Id = "Google.Chrome" },
        @{ Name = "7-Zip"; Id = "7zip.7zip" },
        @{ Name = "AltDrag"; Id = "AltDrag.AltDrag" },
        @{ Name = "Discord"; Id = "Discord.Discord" }
    )
}

function Get-GameLauncherApps {
    return @(
        @{ Name = "Steam"; Id = "Valve.Steam" },
        @{ Name = "Epic Games Launcher"; Id = "EpicGames.EpicGamesLauncher" }
    )
}

function Get-PcTestingUtilityApps {
    return @(
        @{ Name = "HWiNFO"; Id = "REALiX.HWiNFO" },
        @{ Name = "GPU-Z"; Id = "TechPowerUp.GPU-Z" },
        @{ Name = "CPU-Z"; Id = "CPUID.CPU-Z" },
        @{ Name = "Heaven Benchmark"; Id = "Unigine.HeavenBenchmark" },
        @{ Name = "FurMark v1"; Id = "Geeks3D.FurMark.1" },
        @{ Name = "Cinebench R23"; Id = "Maxon.CinebenchR23" },
        @{ Name = "OCCT"; Id = "OCBase.OCCT" }
    )
}

function Install-WorkstationAppBundle {
    Install-AppList -Title "Install workstation apps" -Apps (Get-WorkstationApps) -SetChromeAsDefault
}

function Install-PcTestingUtilityBundle {
    Install-AppList -Title "Install PC testing utilities" -Apps (Get-PcTestingUtilityApps)
}

function Install-GameBundle {
    Install-AppList -Title "Install games" -Apps (Get-GameLauncherApps)

    Start-SteamAppInstall -AppName "Wallpaper Engine" -SteamAppId "431960"
    Start-SteamAppInstall -AppName "Guild Wars 2" -SteamAppId "1284210"

    Write-Host ""
    Write-Host "INFO: Riot Games Client skipped."
    Write-Host "INFO: No reliable standalone winget package for the Riot Games Client was found."
    Write-Host "INFO: Install a specific Riot game manually if you want the Riot client."
}

function Install-AppBundle {
    Install-WorkstationAppBundle
}
