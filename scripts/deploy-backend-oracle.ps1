param(
    [Parameter(Mandatory)][string]$VMHost,
    [Parameter(Mandatory)][string]$SshKeyPath,
    [string]$User = "ubuntu",
    [ValidateSet("GitPull", "Rsync")][string]$Mode = "GitPull",
    [string]$RepositoryUrl = "<REPOSITORY_URL>",
    [string]$Branch = "main"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$BackendRoot = Join-Path $RepoRoot "backend"
$Target = "${User}@${VMHost}"
$RemoteRoot = "/home/$User/apps/replywise"      # Git checkout root
$RemoteBackend = "$RemoteRoot/backend"           # FastAPI working directory
$Service = "replywise-backend.service"

if (-not (Test-Path -LiteralPath $SshKeyPath -PathType Leaf)) {
    throw "SSH key not found: $SshKeyPath"
}

function Write-Section {
    param([Parameter(Mandatory)][string]$Title)
    Write-Host "`n=== $Title ===" -ForegroundColor Cyan
}

Write-Host "ReplyWise Oracle VM deployment command generator" -ForegroundColor Green
Write-Host "No SSH, copy, package, restart, or destructive command will be executed."
Write-Host "Target: $Target"
Write-Host "Mode:   $Mode"

Write-Section "One-time VM preparation"
@"
ssh -i "$SshKeyPath" $Target
sudo apt update
sudo apt install -y git curl jq sqlite3 caddy python3 python3-venv python3-pip
mkdir -p /home/$User/apps
"@ | Write-Host

if ($Mode -eq "GitPull") {
    Write-Section "Initial Git clone (run only when checkout does not exist)"
    @"
ssh -i "$SshKeyPath" $Target
git clone $RepositoryUrl $RemoteRoot
cd $RemoteBackend
python3 -m venv .venv
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -r requirements.txt
"@ | Write-Host

    Write-Section "Safe Git update"
    @"
ssh -i "$SshKeyPath" $Target
cd $RemoteRoot
git status --short
git fetch origin
git checkout $Branch
git pull --ff-only origin $Branch
cd backend
.venv/bin/python -m pip install -r requirements.txt
.venv/bin/python -m pytest
"@ | Write-Host
}
else {
    Write-Section "Rsync source from this workstation"
    Write-Host "Run from a shell that provides rsync:"
    @"
rsync -avz \
  --exclude='.venv' \
  --exclude='.env' \
  --exclude='*.db' \
  --exclude='*.db-shm' \
  --exclude='*.db-wal' \
  --exclude='__pycache__' \
  --exclude='.pytest_cache' \
  -e 'ssh -i "$SshKeyPath"' \
  "$BackendRoot/" "${Target}:${RemoteBackend}/"
"@ | Write-Host
    Write-Host "The command intentionally omits --delete and excludes secrets/database files." -ForegroundColor Yellow
}

Write-Section "Production environment"
@"
ssh -i "$SshKeyPath" $Target
install -m 600 /dev/null $RemoteBackend/.env
nano $RemoteBackend/.env
"@ | Write-Host
Write-Host "Use the production template in docs/ORACLE_VM_BACKEND_DEPLOYMENT.md." -ForegroundColor Yellow
Write-Host "Never copy a local .env or print real secrets." -ForegroundColor Yellow

Write-Section "Validate, restart, and health-check"
@"
ssh -i "$SshKeyPath" $Target
cd $RemoteBackend
.venv/bin/python -m pytest
sudo systemctl daemon-reload
sudo systemctl restart $Service
sudo systemctl status $Service --no-pager
curl --fail --silent --show-error http://127.0.0.1:8003/health
curl --fail --silent --show-error https://api-reply.novaaistudio.ca/health
"@ | Write-Host

Write-Section "Required manual review"
Write-Host "1. Review every printed command before running it."
Write-Host "2. Install the systemd unit and Caddy block from the deployment guide."
Write-Host "3. Enter secrets directly on the VM."
Write-Host "4. Run the authenticated OpenAI smoke tests from the deployment guide."
