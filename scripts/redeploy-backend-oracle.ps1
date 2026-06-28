param(
    [string]$HostName = "170.9.43.177",
    [string]$User     = "ubuntu",
    [string]$SshKey   = "C:\sandbox\APP\ssh-key-oracle_vm.key",
    [string]$Branch   = "main"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Target     = "${User}@${HostName}"
$RepoDir    = "~/apps/replywise"
$BackendDir = "$RepoDir/backend"
$Service    = "replywise-backend"
$HealthUrl  = "https://api-reply.novaaistudio.ca/health"

function Write-Step { param([string]$Msg) Write-Host "`n==> $Msg" -ForegroundColor Cyan }
function Write-Pass { param([string]$Msg) Write-Host "`nPASS: $Msg" -ForegroundColor Green }
function Write-Fail { param([string]$Msg) Write-Host "`nFAIL: $Msg" -ForegroundColor Red; exit 1 }

function Invoke-SSH {
    param(
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][string]$Cmd
    )
    Write-Step $Label
    & ssh -i $SshKey `
          -o "StrictHostKeyChecking=accept-new" `
          -o "BatchMode=yes" `
          -o "ConnectTimeout=15" `
          $Target $Cmd
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "$Label failed (exit $LASTEXITCODE)"
    }
}

# ── Preflight ────────────────────────────────────────────────────────────────

if (-not (Test-Path -LiteralPath $SshKey -PathType Leaf)) {
    Write-Fail "SSH key not found: $SshKey"
}

Write-Host "ReplyWise backend redeploy" -ForegroundColor Green
Write-Host "  Target  : $Target"
Write-Host "  Branch  : $Branch"
Write-Host "  Backend : $BackendDir"
Write-Host "  Health  : $HealthUrl"

# ── Remote steps ─────────────────────────────────────────────────────────────

Invoke-SSH "Git pull" `
    "cd $RepoDir && git pull origin $Branch"

Invoke-SSH "Pip install" `
    "cd $BackendDir && ./.venv/bin/python -m pip install -r requirements.txt"

Invoke-SSH "Restart service" `
    "sudo systemctl restart $Service"

Invoke-SSH "Service status" `
    "sudo systemctl status $Service --no-pager"

Invoke-SSH "Health check" `
    "curl -f --show-error $HealthUrl"

# ── Done ─────────────────────────────────────────────────────────────────────

Write-Pass "Backend redeployed and healthy."
