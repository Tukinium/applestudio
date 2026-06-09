# ============================================================
#  AppleStudio site - initial GitHub setup
#  (Japanese instructions are in GITHUB-手順.md)
#
#  Prereqs:
#    1) Install Git for Windows: https://git-scm.com/download/win
#    2) Create an EMPTY GitHub repo (no README / no .gitignore)
#
#  Usage (run in this folder):
#    PowerShell -ExecutionPolicy Bypass -File .\setup-github.ps1 -RepoUrl "https://github.com/<user>/<repo>.git"
# ============================================================
param(
  [Parameter(Mandatory = $true)][string]$RepoUrl
)
# NOTE: do NOT use 'Stop' here. git writes normal progress to stderr,
# which PowerShell would otherwise treat as a fatal error.
$ErrorActionPreference = "Continue"
Set-Location -Path $PSScriptRoot

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Host "Git not found. Install Git for Windows, then reopen PowerShell." -ForegroundColor Red
  exit 1
}

# Recreate any broken/old .git
if (Test-Path ".git") {
  Write-Host "Removing existing .git and re-initializing..." -ForegroundColor Yellow
  Remove-Item -Recurse -Force ".git"
}
foreach ($junk in @("__probe.txt", "_t.tmp")) {
  if (Test-Path $junk) { Remove-Item -Force $junk }
}

git init | Out-Null
git branch -M main
git config user.email "yosikimizuguti@gmail.com"
git config user.name  "Tukinium"
git add -A
git commit -m "Initial commit: AppleStudio site and Caddy config" 2>&1 | Out-Host
if ($LASTEXITCODE -ne 0) { Write-Host "Commit failed." -ForegroundColor Red; exit 1 }

# Set the remote idempotently (no error if it already exists or not)
$remotes = @(git remote 2>$null)
if ($remotes -contains "origin") {
  git remote set-url origin $RepoUrl
} else {
  git remote add origin $RepoUrl
}

Write-Host ""
Write-Host "Pushing to GitHub. If a sign-in window appears, log in with your GitHub account..." -ForegroundColor Cyan
git push -u origin main 2>&1 | Out-Host
if ($LASTEXITCODE -ne 0) {
  Write-Host "Push failed. Check the repo URL and your GitHub sign-in, then run again." -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "Done. Uploaded to $RepoUrl" -ForegroundColor Green
Write-Host "Next: run register-deploy-task.ps1 in an ADMIN PowerShell to set up the daily 10:00 update." -ForegroundColor Green
