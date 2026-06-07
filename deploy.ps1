# ============================================================
#  Pull the latest from GitHub into this folder (daily update)
#  - Matches origin/main exactly (server is display-only)
#  - Caddy reloads static files automatically (no restart needed)
#  Log: deploy.log
#  (Japanese notes: GITHUB-手順.md)
# ============================================================
# NOTE: 'Continue' (not 'Stop'): git writes progress to stderr,
# which would otherwise be treated as a fatal error.
$ErrorActionPreference = "Continue"
Set-Location -Path $PSScriptRoot
$log = Join-Path $PSScriptRoot "deploy.log"

function Log($m) {
  $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  "[$ts] $m" | Add-Content -Path $log
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Log "git not found"; exit 1 }
if (-not (Test-Path ".git")) { Log ".git missing - run setup-github.ps1 first"; exit 1 }

git fetch origin main 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { Log "fetch failed (network or auth)"; exit 1 }

$local  = (git rev-parse HEAD 2>$null).Trim()
$remote = (git rev-parse origin/main 2>$null).Trim()

if (-not $remote) { Log "could not read origin/main"; exit 1 }

if ($local -eq $remote) {
  Log ("no change (" + $local.Substring(0,7) + ")")
}
else {
  git reset --hard origin/main 2>&1 | Out-Null
  if ($LASTEXITCODE -ne 0) { Log "reset failed"; exit 1 }
  Log ("updated: " + $local.Substring(0,7) + " -> " + $remote.Substring(0,7))
}
