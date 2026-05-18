$ErrorActionPreference = "Stop"

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)

    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Write-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host ""
    Write-Host "==> $Message"
}

function Write-Skip {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "SKIP: $Message"
}

function Set-RegistryDword {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [int]$Value
    )

    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null
    Write-Host "Set $Path\$Name = $Value"
}

function Remove-RegistryValueIfExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if ((Test-Path $Path) -and (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue)) {
        Remove-ItemProperty -Path $Path -Name $Name -Force
        Write-Host "Removed $Path\$Name"
    }
}

function Invoke-Tweak {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )

    Write-Step $Name

    try {
        & $ScriptBlock
    } catch {
        Write-Warning "Failed: $Name. $($_.Exception.Message)"
    }
}

function Disable-AdvertisingId {
    Invoke-Tweak "Disable Advertising ID for current user" {
        Set-RegistryDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0
    }
}

function Disable-TailoredExperiences {
    Invoke-Tweak "Disable Tailored Experiences with diagnostic data for current user" {
        Set-RegistryDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 0
    }
}

function Disable-FeedbackPrompts {
    Invoke-Tweak "Disable feedback prompts for current user" {
        $path = "HKCU:\Software\Microsoft\Siuf\Rules"

        Set-RegistryDword -Path $path -Name "NumberOfSIUFInPeriod" -Value 0
        Remove-RegistryValueIfExists -Path $path -Name "PeriodInNanoSeconds"
    }
}

function Disable-ActivityHistory {
    Invoke-Tweak "Disable Activity History publish/upload via HKLM policy" {
        if (-not (Test-IsAdmin)) {
            Write-Skip "Administrator rights are required for HKLM Activity History policy tweaks."
            return
        }

        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"

        Set-RegistryDword -Path $path -Name "PublishUserActivities" -Value 0
        Set-RegistryDword -Path $path -Name "UploadUserActivities" -Value 0
    }
}

function Disable-StartMenuBingSearch {
    Invoke-Tweak "Disable Start Menu Bing web search" {
        Set-RegistryDword -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Value 1
        Set-RegistryDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0
        Set-RegistryDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaConsent" -Value 0
    }
}

function Show-FileExtensions {
    Invoke-Tweak "Show file extensions" {
        Set-RegistryDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
    }
}

function Show-HiddenFiles {
    Invoke-Tweak "Show hidden files" {
        Set-RegistryDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1
    }
}

function Disable-MouseAcceleration {
    Invoke-Tweak "Disable mouse acceleration" {
        $path = "HKCU:\Control Panel\Mouse"

        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }

        Set-ItemProperty -Path $path -Name "MouseSpeed" -Value "0" -Type String
        Set-ItemProperty -Path $path -Name "MouseThreshold1" -Value "0" -Type String
        Set-ItemProperty -Path $path -Name "MouseThreshold2" -Value "0" -Type String
        Write-Host "Set mouse acceleration values to 0"
    }
}

Disable-AdvertisingId
Disable-TailoredExperiences
Disable-FeedbackPrompts
Disable-ActivityHistory
Disable-StartMenuBingSearch
Show-FileExtensions
Show-HiddenFiles
Disable-MouseAcceleration
