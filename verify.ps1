###############################################################################
# Dev Box Windows Verification Script
# Run in PowerShell to verify Windows-side setup
###############################################################################

$pass = 0
$fail = 0

function Test-Check {
    param([string]$Name, [scriptblock]$Test)
    try {
        $result = & $Test
        if ($result) {
            Write-Host "  PASS  $Name" -ForegroundColor Green
            $script:pass++
        } else {
            Write-Host "  FAIL  $Name" -ForegroundColor Red
            $script:fail++
        }
    } catch {
        Write-Host "  FAIL  $Name ($_)" -ForegroundColor Red
        $script:fail++
    }
}

Write-Host ""
Write-Host "=== Dev Box Windows Verification ===" -ForegroundColor Cyan
Write-Host ""

# --- Apps ---
Write-Host "--- Installed Apps ---"
Test-Check "VS Code installed" { winget list --id Microsoft.VisualStudioCode 2>$null | Select-String "VisualStudioCode" }
Test-Check "Windows Terminal installed" { winget list --id Microsoft.WindowsTerminal 2>$null | Select-String "WindowsTerminal" }
Test-Check "Docker Desktop installed" { winget list --id Docker.DockerDesktop 2>$null | Select-String "DockerDesktop" }
Test-Check "PowerToys installed" { winget list --id Microsoft.PowerToys 2>$null | Select-String "PowerToys" }

# --- Registry settings ---
Write-Host ""
Write-Host "--- Windows Settings ---"
Test-Check "Dark mode (apps)" {
    (Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize").AppsUseLightTheme -eq 0
}
Test-Check "Dark mode (system)" {
    (Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize").SystemUsesLightTheme -eq 0
}
Test-Check "File extensions visible" {
    (Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced").HideFileExt -eq 0
}
Test-Check "Search box hidden" {
    (Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search").SearchboxTaskbarMode -eq 0
}
Test-Check "Widgets hidden" {
    (Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced").TaskbarDa -eq 0
}

# --- Edge ---
Write-Host ""
Write-Host "--- Edge ---"
Test-Check "Edge first-run skipped" {
    (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Edge").HideFirstRunExperience -eq 1
}

# --- Bloatware removed ---
Write-Host ""
Write-Host "--- Bloatware Removed ---"
$bloatware = @(
    @("Microsoft.YourPhone", "Your Phone"),
    @("microsoft.windowscommunicationsapps", "Mail and Calendar"),
    @("Clipchamp.Clipchamp", "Clipchamp"),
    @("Microsoft.Getstarted", "Tips"),
    @("Microsoft.People", "People"),
    @("Microsoft.WindowsCamera", "Camera"),
    @("Microsoft.WindowsMaps", "Maps"),
    @("Microsoft.BingWeather", "Weather")
)
foreach ($app in $bloatware) {
    $appId = $app[0]
    $appName = $app[1]
    Test-Check "$appName removed" {
        $match = winget list --id $appId 2>$null | Select-String $appId
        -not $match
    }.GetNewClosure()
}

# --- Docker ---
Write-Host ""
Write-Host "--- Docker Desktop ---"
Test-Check "Docker Desktop running" { Get-Process "Docker Desktop" -ErrorAction SilentlyContinue }
Test-Check "Docker settings exist" { Test-Path "$env:APPDATA\Docker\settings.json" }
if (Test-Path "$env:APPDATA\Docker\settings.json") {
    $docker = Get-Content "$env:APPDATA\Docker\settings.json" | ConvertFrom-Json
    Test-Check "Docker starts at login" { $docker.startAtLogin -eq $true }
    Test-Check "Docker auto-pause disabled" { $docker.autoPause -eq $false }
    Test-Check "Docker resource saver disabled" { $docker.useResourceSaver -eq $false }
    Test-Check "Docker hibernate disabled" { $docker.hibernateOnStop -eq $false }
    Test-Check "Docker WSL engine enabled" { $docker.wslEngineEnabled -eq $true }
    Test-Check "Docker Ubuntu integration" { $docker.integratedWslDistros -contains "Ubuntu" }
}

# --- WSL ---
Write-Host ""
Write-Host "--- WSL ---"
Test-Check "WSL installed" { wsl --status 2>$null }
Test-Check "Ubuntu distro available" { wsl -l -q 2>$null | Select-String "Ubuntu" }
Test-Check ".wslconfig exists" { Test-Path "$env:USERPROFILE\.wslconfig" }

# --- Summary ---
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Results: $pass passed, $fail failed" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Red" })
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
