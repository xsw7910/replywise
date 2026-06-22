Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot

function Write-Section {
    param([Parameter(Mandatory)][string]$Title)
    Write-Host "`n=== $Title ===" -ForegroundColor Cyan
}

Write-Host "ReplyWise review preparation" -ForegroundColor Green
Write-Host "Repository: $RepoRoot"

Write-Section "Running local checks"
& (Join-Path $PSScriptRoot "test.ps1")

Push-Location $RepoRoot
try {
    Write-Section "Git status"
    & git status --short
    if ($LASTEXITCODE -ne 0) {
        throw "git status failed with exit code $LASTEXITCODE."
    }

    Write-Section "Changed files summary"
    & git diff --stat HEAD
    if ($LASTEXITCODE -ne 0) {
        throw "git diff failed with exit code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}

Write-Section "Ready for review"
Write-Host "No commit or push was performed."

