###############################################################################
# Dev Box Windows Bootstrap Script
# Run by devbox.yaml after git-clone pulls this repo to C:\devbox-dotfiles
###############################################################################

$dotfiles = "C:\devbox-dotfiles"

# --- System-wide Dark Mode ---
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 0 /f

# --- Edge: skip first-run experience ---
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v HideFirstRunExperience /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v AutoImportAtFirstRun /t REG_DWORD /d 4 /f

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

# --- .wslconfig (WSL resource limits) ---
Copy-Item "$dotfiles\.wslconfig" "$env:USERPROFILE\.wslconfig" -Force

# --- Docker Desktop settings ---
$dockerDir = "$env:APPDATA\Docker"
New-Item -ItemType Directory -Path $dockerDir -Force
Copy-Item "$dotfiles\docker-settings.json" "$dockerDir\settings.json" -Force

Write-Host "Windows bootstrap complete."
