param(
    [switch]$ResetDb,
    [switch]$MockPremium,
    [int]$MockPaidCredits = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$BackendRoot = Join-Path $RepoRoot "backend"
$VenvPython = Join-Path $BackendRoot ".venv\Scripts\python.exe"
$Requirements = Join-Path $BackendRoot "requirements.txt"
$DbPath = Join-Path $BackendRoot "replywise.db"

Set-Location $BackendRoot

if (-not (Test-Path $VenvPython)) {
    Write-Host "Creating virtual environment..." -ForegroundColor Cyan
    python -m venv .venv
}

Write-Host "Installing/updating requirements..." -ForegroundColor Cyan
& $VenvPython -m pip install -q -r $Requirements

if ($ResetDb -and (Test-Path $DbPath)) {
    Write-Host "Resetting database..." -ForegroundColor Yellow
    Remove-Item $DbPath -Force
}

$env:REPLY_ENV = "dev"
$env:MOCK_AI_ENABLED = "true"
$env:DEV_TOOLS_ENABLED = "true"
$env:MOCK_PREMIUM = if ($MockPremium) { "true" } else { "false" }
$env:MOCK_PAID_CREDITS = "$MockPaidCredits"

Write-Host "Starting backend (mock mode)..." -ForegroundColor Green
Write-Host "  MOCK_AI_ENABLED=true  DEV_TOOLS_ENABLED=true  MOCK_PREMIUM=$($env:MOCK_PREMIUM)  MOCK_PAID_CREDITS=$MockPaidCredits" -ForegroundColor DarkGray
& $VenvPython -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
