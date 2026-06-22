Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot

function Write-Section {
    param([Parameter(Mandatory)][string]$Title)
    Write-Host "`n=== $Title ===" -ForegroundColor Cyan
}

function Invoke-Checked {
    param(
        [Parameter(Mandatory)][string]$Command,
        [Parameter()][string[]]$Arguments = @()
    )

    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Command failed with exit code $LASTEXITCODE."
    }
}

Write-Host "ReplyWise local test suite" -ForegroundColor Green
Write-Host "Repository: $RepoRoot"

Write-Section "Flutter analyze"
Push-Location (Join-Path $RepoRoot "app")
try {
    Invoke-Checked "flutter" @("analyze")
}
finally {
    Pop-Location
}

Write-Section "Flutter tests"
Push-Location (Join-Path $RepoRoot "app")
try {
    Invoke-Checked "flutter" @("test")
}
finally {
    Pop-Location
}

Write-Section "Backend tests"
Push-Location (Join-Path $RepoRoot "backend")
try {
    $Python = Join-Path (Get-Location) ".venv\Scripts\python.exe"
    Invoke-Checked $Python @("-m", "pytest")
}
finally {
    Pop-Location
}

Write-Section "All checks passed"

