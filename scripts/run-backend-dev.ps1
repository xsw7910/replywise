Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$BackendRoot = Join-Path $RepoRoot "backend"
$VenvPython = Join-Path $BackendRoot ".venv\Scripts\python.exe"
$Requirements = Join-Path $BackendRoot "requirements.txt"

Set-Location $BackendRoot

if (-not (Test-Path $VenvPython)) {
    Write-Host "Creating virtual environment..." -ForegroundColor Cyan
    python -m venv .venv
}

Write-Host "Installing/updating requirements..." -ForegroundColor Cyan
& $VenvPython -m pip install -q -r $Requirements

$env:REPLY_ENV = "dev"
$env:MOCK_AI_ENABLED = "false"
$env:DEV_TOOLS_ENABLED = "false"

Write-Host "Starting backend (dev mode)..." -ForegroundColor Green
& $VenvPython -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
