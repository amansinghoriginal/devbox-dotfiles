###############################################################################
# Dev Box Windows Bootstrap Script
# Run by devbox.yaml after git-clone pulls this repo to C:\devbox-dotfiles
###############################################################################

# Auto-detect script location so paths work regardless of clone depth
$dotfiles = $PSScriptRoot

# --- System-wide Dark Mode ---
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 0 /f

# --- Show file extensions ---
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f

# --- Hide search box from taskbar ---
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode /t REG_DWORD /d 0 /f

# --- Hide widgets button from taskbar ---
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f

# --- Always show all system tray icons (never collapse) ---
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v EnableAutoTray /t REG_DWORD /d 0 /f

# --- Edge: skip first-run experience ---
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v HideFirstRunExperience /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v AutoImportAtFirstRun /t REG_DWORD /d 4 /f

# --- Remove Windows bloatware ---
$bloatware = @(
    "Microsoft.YourPhone"
    "microsoft.windowscommunicationsapps"
    "Clipchamp.Clipchamp"
    "Microsoft.Getstarted"
    "Microsoft.People"
    "Microsoft.WindowsCamera"
    "Microsoft.WindowsMaps"
    "Microsoft.BingWeather"
)
foreach ($app in $bloatware) {
    winget uninstall $app --accept-source-agreements --silent 2>$null | Out-Null
    # Silently skip apps that aren't installed
}

# --- Windows Terminal as default terminal ---
reg add "HKCU\Console\%%Startup" /v DelegationConsole /t REG_SZ /d "{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}" /f
reg add "HKCU\Console\%%Startup" /v DelegationTerminal /t REG_SZ /d "{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}" /f

# --- Taskbar: apply layout then unlock ---
Copy-Item "$dotfiles\taskbar-layout.xml" "C:\Users\Default\taskbar-layout.xml" -Force
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v StartLayoutFile /t REG_EXPAND_SZ /d "C:\Users\Default\taskbar-layout.xml" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v LockedStartLayout /t REG_DWORD /d 1 /f
Stop-Process -Name explorer -Force
Start-Sleep -Seconds 2
Start-Process explorer
Start-Sleep -Seconds 3
# Unlock so user can modify pins later
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v LockedStartLayout /t REG_DWORD /d 0 /f
Stop-Process -Name explorer -Force
Start-Process explorer

# --- Windows Terminal: launch once to generate settings, then configure ---
Start-Process wt.exe -ArgumentList "--help" -WindowStyle Hidden -ErrorAction SilentlyContinue
Start-Sleep -Seconds 5
Stop-Process -Name WindowsTerminal -Force -ErrorAction SilentlyContinue

$wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $wtSettingsPath) {
    $content = Get-Content $wtSettingsPath -Raw
    # Find Ubuntu profile GUID via regex
    if ($content -match '"name"\s*:\s*"Ubuntu"' -and $content -match '"guid"\s*:\s*"(\{[^}]+\})"') {
        $ubuntuGuid = $Matches[1]
        # Replace defaultProfile value with Ubuntu GUID using string replacement
        $content = $content -replace '"defaultProfile"\s*:\s*"[^"]*"', "`"defaultProfile`": `"$ubuntuGuid`""
        Set-Content $wtSettingsPath -Value $content -Encoding UTF8 -NoNewline
    }
} else {
    # Terminal not launched yet — create minimal settings pointing to Ubuntu
    $wtSettingsDir = Split-Path $wtSettingsPath
    New-Item -ItemType Directory -Path $wtSettingsDir -Force
    Set-Content $wtSettingsPath -Value '{ "defaultProfile": "{2c4de342-38b7-51cf-b940-2309a097f518}" }' -Encoding UTF8
}

# --- Solid desktop background (no wallpaper) ---
reg add "HKCU\Control Panel\Desktop" /v WallPaper /t REG_SZ /d " " /f
RUNDLL32.EXE USER32.DLL,UpdatePerUserSystemParameters

# --- .wslconfig (WSL resource limits) ---
Copy-Item "$dotfiles\.wslconfig" "$env:USERPROFILE\.wslconfig" -Force

# --- Docker Desktop: apply settings (install handled by devbox.yaml) ---
$dockerDir = "$env:APPDATA\Docker"
New-Item -ItemType Directory -Path $dockerDir -Force
Copy-Item "$dotfiles\docker-settings.json" "$dockerDir\settings.json" -Force

# --- Clean up desktop shortcuts left by installers ---
Remove-Item "$env:USERPROFILE\Desktop\*.lnk" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:PUBLIC\Desktop\*.lnk" -Force -ErrorAction SilentlyContinue

Write-Host "Windows bootstrap complete."
