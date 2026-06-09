# ============================================================
#  Register a Windows Scheduled Task that runs deploy.ps1
#  (GitHub update) every day at 10:00.
#  Run this in an ADMIN PowerShell.
#  (Japanese notes: GITHUB-手順.md)
# ============================================================
$ErrorActionPreference = "Stop"
$scriptPath = Join-Path $PSScriptRoot "deploy.ps1"

if (-not (Test-Path $scriptPath)) {
  Write-Host "deploy.ps1 not found." -ForegroundColor Red
  exit 1
}

$action = New-ScheduledTaskAction -Execute "powershell.exe" `
  -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""

# Daily at 10:00. If the PC was off at that time, run when it next becomes available.
$trigger = New-ScheduledTaskTrigger -Daily -At 10:00am

$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable `
  -DontStopOnIdleEnd -ExecutionTimeLimit (New-TimeSpan -Minutes 10)

# Run whether or not the user is logged on (server use). Runs as current user.
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" `
  -LogonType S4U -RunLevel Limited

Register-ScheduledTask -TaskName "AppleStudio-Deploy" `
  -Description "Daily 10:00 update of AppleStudio site from GitHub" `
  -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null

Write-Host "Registered: task 'AppleStudio-Deploy' runs every day at 10:00." -ForegroundColor Green
Write-Host "Test now:  Start-ScheduledTask -TaskName 'AppleStudio-Deploy'" -ForegroundColor Cyan
Write-Host "Results are written to deploy.log" -ForegroundColor Cyan
