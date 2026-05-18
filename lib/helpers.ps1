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

function Write-Stage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host ""
    Write-Host $Message
    Write-Host ("-" * $Message.Length)
}

function Test-CommandExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-PathExists {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Path
    )

    foreach ($item in $Path) {
        if ($item -and (Test-Path $item)) {
            return $true
        }
    }

    return $false
}

function Write-SummaryItem {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("PASS", "WARN", "INFO")]
        [string]$Status,

        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "${Status}: $Message"
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

function Remove-RegistryKeyIfExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (Test-Path $Path) {
        Remove-Item -Path $Path -Recurse -Force
        Write-Host "Removed $Path"
    } else {
        Write-Host "INFO: Registry path does not exist: $Path"
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
