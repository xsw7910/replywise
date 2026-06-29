# ReplyWise Backend Deployment on Oracle Free VM

Production target:

- Public API: `https://api-reply.novaaistudio.ca`
- Uvicorn bind: `127.0.0.1:8003`
- Service: `replywise-backend.service`
- Runtime: Python 3.12 when available
- TLS/reverse proxy: Caddy

This follows the same production pattern used by HairTrack AI and Rental Expense Keeper: application code in `/home/ubuntu/apps`, Uvicorn bound only to localhost, systemd process supervision, and Caddy-managed HTTPS.

No command in this guide contains a real secret. Enter secrets directly on the VM.

## 1. Server layout

```text
/home/ubuntu/apps/replywise/    # Git checkout (full repo)
  backend/                      # FastAPI backend — working directory
    app/                        # Application source
    .venv/                      # Python virtualenv (not in Git)
    .env                        # Secrets (not in Git, created on VM)
    replywise.db                # SQLite database (not in Git)
    requirements.txt
    pytest.ini
```

The `.env` and `replywise.db` live directly in the backend folder. They are gitignored and survive `git pull`.

## 2. DNS, firewall, and packages

Create an `A` record:

```text
api-reply.novaaistudio.ca -> <ORACLE_VM_PUBLIC_IP>
```

Oracle Cloud ingress and the VM firewall should allow ports `22`, `80`, and `443`. Do **not** expose port `8003`; Caddy reaches it through localhost.

```bash
sudo apt update
sudo apt install -y git curl jq sqlite3 caddy python3 python3-venv python3-pip
python3 --version
```

If Ubuntu provides Python 3.12:

```bash
sudo apt install -y python3.12 python3.12-venv
PYTHON_BIN=python3.12
```

Otherwise:

```bash
PYTHON_BIN=python3
```

## 3. Create directories and clone

Replace `<REPOSITORY_URL>` with the real Git URL. Use an SSH deploy key or another non-password Git credential if the repository is private.

```bash
mkdir -p /home/ubuntu/apps
git clone <REPOSITORY_URL> /home/ubuntu/apps/replywise
cd /home/ubuntu/apps/replywise/backend

$PYTHON_BIN -m venv .venv
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -r requirements.txt
```

For an existing checkout:

```bash
cd /home/ubuntu/apps/replywise
git status --short
git fetch origin
git checkout main
git pull --ff-only origin main

cd backend
.venv/bin/python -m pip install -r requirements.txt
```

Do not run `git reset --hard` on the VM. Investigate unexpected local changes instead.

## 4. Production environment

Create the `.env` file directly in the backend folder:

```bash
install -m 600 /dev/null /home/ubuntu/apps/replywise/backend/.env
nano /home/ubuntu/apps/replywise/backend/.env
```

Generate separate random values for `JWT_SECRET` and `SERVER_PEPPER`:

```bash
python3 -c "import secrets; print(secrets.token_hex(32))"
python3 -c "import secrets; print(secrets.token_hex(32))"
```

Production template:

```dotenv
REPLY_ENV=prod
APP_ENV=prod
SERVICE_NAME=reply-backend
DATABASE_URL=sqlite+aiosqlite:////home/ubuntu/apps/replywise/backend/replywise.db

JWT_SECRET=<64-character-random-hex>
SERVER_PEPPER=<different-64-character-random-hex>

OPENAI_API_KEY=<set-directly-on-the-VM>
OPENAI_MODEL=gpt-4o-mini
OPENAI_TIMEOUT_SECONDS=30

# v2 API — must use a v2-compatible secret key (not a v1 key)
# REVENUECAT_PROJECT_ID: RevenueCat dashboard → Project Settings → Project ID
REVENUECAT_SECRET_API_KEY=<RevenueCat-v2-compatible-secret-key>
REVENUECAT_PROJECT_ID=<proj_xxxxxxxxxxxxxxxx>
REVENUECAT_ENTITLEMENT_ID=premium
REVENUECAT_SUBSCRIPTION_PRODUCT_ID=premium_yearly:yearly

MOCK_AI_ENABLED=false
DEV_TOOLS_ENABLED=false
ALLOWED_ORIGINS=*

EXPLAIN_DAILY_LIMIT=10
FREE_LIFETIME_LIMIT=5
GENERATION_RATE_PER_MINUTE=8
IDEMPOTENCY_TTL_SECONDS=86400
```

Production startup intentionally fails when:

- `OPENAI_API_KEY` is empty.
- `REVENUECAT_SECRET_API_KEY` is empty.
- development JWT/pepper values are used.
- `MOCK_AI_ENABLED=true`.
- `DEV_TOOLS_ENABLED=true`.

Do not put `.env`, API keys, the SQLite database, WAL/SHM files, or backups in Git.

## 5. systemd service

Create `/etc/systemd/system/replywise-backend.service`:

```ini
[Unit]
Description=ReplyWise FastAPI Backend
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=ubuntu
Group=ubuntu
WorkingDirectory=/home/ubuntu/apps/replywise/backend
EnvironmentFile=/home/ubuntu/apps/replywise/backend/.env
Environment=PYTHONUNBUFFERED=1
ExecStart=/home/ubuntu/apps/replywise/backend/.venv/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 8003
Restart=always
RestartSec=5
UMask=0077

[Install]
WantedBy=multi-user.target
```

Install and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now replywise-backend.service
sudo systemctl status replywise-backend.service --no-pager
```

Local VM health check:

```bash
curl --fail --silent --show-error http://127.0.0.1:8003/health
```

Expected:

```json
{"status":"ok","service":"reply-backend"}
```

## 6. Caddy

Edit `/etc/caddy/Caddyfile` and add:

```caddyfile
api-reply.novaaistudio.ca {
    reverse_proxy 127.0.0.1:8003
}
```

Validate, format, and reload:

```bash
sudo caddy validate --config /etc/caddy/Caddyfile
sudo caddy fmt --overwrite /etc/caddy/Caddyfile
sudo systemctl reload caddy
sudo systemctl status caddy --no-pager
```

Public health check:

```bash
curl --fail --silent --show-error https://api-reply.novaaistudio.ca/health
```

## 7. Authenticated real OpenAI smoke tests

Production rejects mock AI and requires an OpenAI key, so a successfully started prod service uses the real OpenAI provider.

Create a unique anonymous test identity:

```bash
BASE_URL=https://api-reply.novaaistudio.ca
APP_USER_ID="oracle-smoke-$(date +%s)"
DEVICE_ID="oracle-smoke-device-$(date +%s)"

AUTH_RESPONSE=$(
  curl --fail --silent --show-error \
    -X POST "$BASE_URL/v1/auth/anonymous" \
    -H "Content-Type: application/json" \
    -d "{
      \"appUserId\":\"$APP_USER_ID\",
      \"deviceId\":\"$DEVICE_ID\",
      \"platform\":\"android\"
    }"
)

TOKEN=$(printf '%s' "$AUTH_RESPONSE" | jq -r '.accessToken')
test -n "$TOKEN" && test "$TOKEN" != "null"
```

Reply:

```bash
curl --fail --silent --show-error \
  -X POST "$BASE_URL/v1/reply" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Idempotency-Key: smoke-reply-$(date +%s)" \
  -d '{
    "incoming":"Can we move the meeting to Friday afternoon?",
    "guidance":"Agree politely and ask them to confirm the time.",
    "guidanceLang":"en",
    "audience":{"mode":"auto","formality":55}
  }' | jq
```

Polish:

```bash
curl --fail --silent --show-error \
  -X POST "$BASE_URL/v1/polish" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Idempotency-Key: smoke-polish-$(date +%s)" \
  -d '{
    "draft":"Hi, just checking if you saw my last message.",
    "direction":"professional",
    "guidanceLang":"en"
  }' | jq
```

Explain:

```bash
curl --fail --silent --show-error \
  -X POST "$BASE_URL/v1/explain" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "text":"That sounds fine in principle, but let us revisit it next quarter.",
    "explainLang":"en"
  }' | jq
```

Confirm that:

- Reply returns exactly `Professional`, `Friendly`, and `Short` versions.
- Polish returns `polished` and `changes`.
- Explain returns `meaning`, `tone`, `hiddenMeaning`, and `suggestedReplies`.
- No response contains an OpenAI exception, request ID, API key, or raw provider message.

These calls consume the configured free usage for the smoke-test identity.

## 8. Logs and troubleshooting

Backend:

```bash
sudo systemctl status replywise-backend.service --no-pager
sudo journalctl -u replywise-backend.service -f
sudo journalctl -u replywise-backend.service -n 200 --no-pager
sudo systemctl restart replywise-backend.service
```

Caddy:

```bash
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl status caddy --no-pager
sudo journalctl -u caddy -n 200 --no-pager
sudo systemctl reload caddy
```

DNS/TLS:

```bash
dig +short api-reply.novaaistudio.ca
curl -v https://api-reply.novaaistudio.ca/health
```

Listening sockets and firewall:

```bash
sudo ss -ltnp | grep -E ':8003|:80|:443'
sudo ufw status verbose
```

Common failures:

- Startup validation error: check required `.env` variables and ensure both local-only flags are false.
- `502` from Caddy: check `replywise-backend.service` and verify `127.0.0.1:8003/health`.
- OpenAI `MODEL_CONFIGURATION_ERROR`: verify the VM-only key and model access.
- OpenAI `MODEL_UNAVAILABLE`/`MODEL_RATE_LIMITED`: inspect service status, outbound connectivity, and account limits; raw provider details are intentionally not returned to clients.
- SQLite write error: verify `ubuntu` can write `/home/ubuntu/apps/replywise/backend` and that the disk is not full.

## 9. Database backup

Use SQLite's online backup command:

```bash
BACKUP="/home/ubuntu/apps/replywise/backend/replywise-backup-$(date +%Y%m%d-%H%M%S).db"
sqlite3 /home/ubuntu/apps/replywise/backend/replywise.db ".backup '$BACKUP'"
ls -lh "$BACKUP"
```

Copy a backup off the VM from your workstation:

```bash
scp -i <SSH_KEY_PATH> ubuntu@<VM_HOST>:/home/ubuntu/apps/replywise/backend/replywise-backup-<DATE>.db .
```

## 10. Safe update

### Automated redeploy (recommended after initial setup)

After pushing code to GitHub, run from your Windows workstation:

```powershell
.\scripts\redeploy-backend-oracle.ps1
```

The script pulls the latest code, installs dependencies, restarts the service, and verifies the public health endpoint. It fails fast if any step fails.

Default parameters match the production VM. Override when needed:

| Parameter | Default |
|-----------|---------|
| `-HostName` | `170.9.43.177` |
| `-User` | `ubuntu` |
| `-SshKey` | `C:\sandbox\APP\ssh-key-oracle_vm.key` |
| `-Branch` | `main` |

Example with explicit values:

```powershell
.\scripts\redeploy-backend-oracle.ps1 -Branch main -HostName 170.9.43.177
```

### Manual update

If you need to run steps individually or the script is unavailable:

```bash
cd /home/ubuntu/apps/replywise
git status --short
git fetch origin
git checkout main
git pull --ff-only origin main

cd backend
.venv/bin/python -m pip install -r requirements.txt
.venv/bin/python -m pytest

sudo systemctl restart replywise-backend.service
sudo systemctl status replywise-backend.service --no-pager
curl --fail --silent --show-error http://127.0.0.1:8003/health
curl --fail --silent --show-error https://api-reply.novaaistudio.ca/health
```

The `.env` and `replywise.db` survive because they are gitignored and `git pull` does not touch them.

## 11. Rollback

Before updating, record the current commit and create a database backup:

```bash
cd /home/ubuntu/apps/replywise
git rev-parse HEAD
sqlite3 /home/ubuntu/apps/replywise/backend/replywise.db \
  ".backup '/home/ubuntu/apps/replywise/backend/replywise-pre-rollback.db'"
```

To roll back code, replace `<KNOWN_GOOD_COMMIT>`:

```bash
cd /home/ubuntu/apps/replywise
git status --short
git checkout <KNOWN_GOOD_COMMIT>

cd backend
.venv/bin/python -m pip install -r requirements.txt
.venv/bin/python -m pytest
sudo systemctl restart replywise-backend.service
curl --fail --silent --show-error https://api-reply.novaaistudio.ca/health
```

Return to the deployment branch later with:

```bash
cd /home/ubuntu/apps/replywise
git checkout main
git pull --ff-only origin main
```

Do not restore an older database unless schema/data compatibility requires it and a rollback has been tested.

## 12. Pre-Google-Play manual checklist

- DNS resolves to the Oracle VM.
- Caddy has a valid certificate and public `/health` succeeds.
- Production `.env` contains unique JWT/pepper values and VM-only OpenAI/RevenueCat secrets.
- Existing RevenueCat entitlement and product identifiers are verified unchanged.
- `REVENUECAT_SECRET_API_KEY` is a **v2-compatible** key (v1 keys return HTTP 403 on v2 endpoints).
- `REVENUECAT_PROJECT_ID` is set to the project ID from the RevenueCat dashboard → Project Settings.
- Reply, Polish, Explain, entitlement sync, and credits sync pass against production.
- Service restart preserves auth, usage, entitlement cache, credits, and idempotency records.
- A database backup is copied off the VM and restore steps are tested.
- The Flutter internal AAB is built with:

  ```text
  --dart-define=REPLY_BACKEND_BASE_URL=https://api-reply.novaaistudio.ca
  --dart-define=REPLY_ENV=prod
  --dart-define=DEV_TOOLS_ENABLED=false
  ```

- Run the repository release/review checks before manually uploading to Google Play internal testing.

This guide does not deploy automatically and does not upload anything to Google Play.
