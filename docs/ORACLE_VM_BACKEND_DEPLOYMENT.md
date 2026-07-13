# ReplyWise Backend Deployment on Oracle Free VM

Production target:

- Public API: `https://api-reply.novaaistudio.ca`
- API container bind: `127.0.0.1:8000`
- Services: Docker Compose `api` + PostgreSQL 16
- Runtime: Python 3.12 container
- TLS/reverse proxy: Caddy

Application code lives in `/home/ubuntu/apps`, PostgreSQL data is stored in a
named Docker volume, and Caddy terminates HTTPS in front of the API container.

No command in this guide contains a real secret. Enter secrets directly on the VM.

## 1. Server layout

```text
/home/ubuntu/apps/replywise/    # Git checkout (full repo)
  backend/                      # FastAPI backend — working directory
    app/                        # Application source
    alembic/                    # Database migrations
    alembic.ini
    .env                        # Secrets (not in Git, created on VM)
    docker-compose.yml
    requirements.txt
```

The `.env` lives directly in the backend folder and is gitignored. PostgreSQL
data lives in the `postgres_data` named volume and survives container rebuilds
and `git pull`.

## 2. DNS, firewall, and packages

Create an `A` record:

```text
api-reply.novaaistudio.ca -> <ORACLE_VM_PUBLIC_IP>
```

Oracle Cloud ingress and the VM firewall should allow ports `22`, `80`, and
`443`. Do **not** expose the API or PostgreSQL ports publicly.

```bash
sudo apt update
sudo apt install -y git curl jq caddy docker.io docker-compose-v2
sudo systemctl enable --now docker
docker --version
docker compose version
```

## 3. Create directories and clone

Replace `<REPOSITORY_URL>` with the real Git URL. Use an SSH deploy key or another non-password Git credential if the repository is private.

```bash
mkdir -p /home/ubuntu/apps
git clone <REPOSITORY_URL> /home/ubuntu/apps/replywise
cd /home/ubuntu/apps/replywise/backend
```

For an existing checkout:

```bash
cd /home/ubuntu/apps/replywise
git status --short
git fetch origin
git checkout main
git pull --ff-only origin main

cd backend
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
POSTGRES_PASSWORD=<strong-url-safe-postgres-password>
DATABASE_URL=postgresql+asyncpg://replywise:<same-url-safe-postgres-password>@postgres:5432/replywise

JWT_SECRET=<64-character-random-hex>
SERVER_PEPPER=<different-64-character-random-hex>

OPENAI_API_KEY=<set-directly-on-the-VM>
OPENAI_MODEL=gpt-4o-mini
OPENAI_TIMEOUT_SECONDS=30

# v2 API — must use a v2-compatible secret key (not a v1 key)
# REVENUECAT_PROJECT_ID: RevenueCat dashboard → Project Settings → Project ID
# REVENUECAT_WEBHOOK_SECRET: the Authorization value configured on the RevenueCat
#   webhook (see section 7). Generate with: python3 -c "import secrets; print(secrets.token_hex(32))"
REVENUECAT_SECRET_API_KEY=<RevenueCat-v2-compatible-secret-key>
REVENUECAT_WEBHOOK_SECRET=<random-webhook-authorization-secret>
REVENUECAT_PROJECT_ID=<proj_xxxxxxxxxxxxxxxx>
REVENUECAT_ENTITLEMENT_ID=premium
REVENUECAT_SUBSCRIPTION_PRODUCT_ID=premium_yearly:yearly
REVENUECAT_CREDIT_PRODUCT_MAP=credits_10:10,credits_50:50,credits_100:100

MOCK_AI_ENABLED=false
DEV_TOOLS_ENABLED=false
ALLOWED_ORIGINS=*

EXPLAIN_DAILY_LIMIT=10
FREE_LIFETIME_LIMIT=5
GENERATION_RATE_PER_MINUTE=8
IDEMPOTENCY_TTL_SECONDS=86400
```

Production startup intentionally fails when:

- `DATABASE_URL` is SQLite or is not `postgresql+asyncpg://`.
- `OPENAI_API_KEY` is empty.
- `REVENUECAT_SECRET_API_KEY` is empty.
- `REVENUECAT_WEBHOOK_SECRET` is empty.
- `REVENUECAT_PROJECT_ID` or `REVENUECAT_CREDIT_PRODUCT_MAP` is empty.
- development JWT/pepper values are used.
- `MOCK_AI_ENABLED=true`.
- `DEV_TOOLS_ENABLED=true`.

Do not put `.env`, API keys, database dumps, or backups in Git. Direct local
development and pytest may continue using `sqlite+aiosqlite`; production must
use PostgreSQL.

## 5. PostgreSQL migration and API startup

Production **must** use PostgreSQL with the asyncpg driver
(`DATABASE_URL=postgresql+asyncpg://…`). With `REPLY_ENV=prod` the backend
**rejects any SQLite URL at startup** and **does not create tables
automatically** — `Base.metadata.create_all()` runs only in dev/test. Therefore
the schema must be applied with Alembic **before** the API starts, or every
request will fail against an empty database.

Apply every migration before starting or updating the API:

```bash
cd backend        # /home/ubuntu/apps/replywise/backend on the VM
docker compose build api
docker compose up -d postgres
docker compose run --rm api alembic upgrade head
docker compose up -d api
curl -fsS http://localhost:8000/health
docker compose logs --tail=30 api
```

A one-shot `migrate` service is also wired in: `api` `depends_on` it with
`condition: service_completed_successfully`, so **`docker compose up -d api`
automatically runs `alembic upgrade head` first** (via `postgres → migrate →
api`) and refuses to start the API if the migration fails. The explicit
`docker compose run --rm api alembic upgrade head` above remains valid and
idempotent — running it when already at head is a no-op.

If `alembic upgrade head` fails, **do not start the API**. Confirm the applied
revision at any time with:

```bash
docker compose run --rm api alembic current   # should report the latest head
```

Expected health response:

```json
{"status":"ok","service":"reply-backend"}
```

Expected:

```json
{"status":"ok","service":"reply-backend"}
```

## 6. Caddy

Edit `/etc/caddy/Caddyfile` and add:

```caddyfile
api-reply.novaaistudio.ca {
    reverse_proxy 127.0.0.1:8000
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

## 7. RevenueCat webhook configuration

The backend exposes a webhook so RevenueCat can push entitlement and purchase
changes in real time (subscription renew/cancel/refund/expiration and credit
purchases). This complements the client-side `/v1/entitlement/sync` and
`/v1/credits/sync`, which remain as a fallback if a webhook is ever missed.

In the RevenueCat dashboard → Project → Integrations → Webhooks, add:

- **URL**: `https://api-reply.novaaistudio.ca/v1/webhooks/revenuecat`
  (replace with your production domain; must be the HTTPS Caddy endpoint).
- **Authorization header**: set it to the **raw value** of
  `REVENUECAT_WEBHOOK_SECRET` from the production `.env` — **do not add a
  `Bearer` prefix or any other decoration**. The header must equal the secret
  exactly (compared in constant time). A missing, mismatched, or
  `Bearer`-prefixed value returns `401`.

Recommended events to enable (any other event type is safely ignored):

```text
INITIAL_PURCHASE
RENEWAL
UNCANCELLATION
PRODUCT_CHANGE
EXPIRATION
CANCELLATION
BILLING_ISSUE
REFUND
NON_RENEWING_PURCHASE
```

Behavior:

- `INITIAL_PURCHASE` / `RENEWAL` / `UNCANCELLATION` / `PRODUCT_CHANGE` mark the
  user's cached entitlement **active** (premium on).
- `EXPIRATION` / `CANCELLATION` / `BILLING_ISSUE` / `REFUND` mark it **inactive**
  (premium off).
- `NON_RENEWING_PURCHASE` grants credits per `REVENUECAT_CREDIT_PRODUCT_MAP`.
- Every event is de-duplicated by RevenueCat `event.id`, and credit grants are
  additionally de-duplicated by transaction id, so replays never double-apply.

Verify after configuring — send a test request from the VM (or use RevenueCat's
"Send test event" button). The raw secret returns `200`; a wrong, absent, or
`Bearer`-prefixed value returns `401`. `$REVENUECAT_WEBHOOK_SECRET` is read from
the shell environment — never paste the real secret into shared logs.

```bash
curl -i -X POST https://api-reply.novaaistudio.ca/v1/webhooks/revenuecat \
  -H "Content-Type: application/json" \
  -H "Authorization: $REVENUECAT_WEBHOOK_SECRET" \
  -d '{"event":{"id":"test_webhook_001","type":"INITIAL_PURCHASE","app_user_id":"test_user","product_id":"premium_yearly","transaction_id":"test_txn_001"}}'
```

Then optionally confirm the backend handled it:

```bash
docker compose logs --tail=50 api | grep -i webhook
```

## 8. Authenticated real OpenAI smoke tests

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

- Reply returns exactly `Formal`, `Casual`, and `Concise` versions.
- Polish returns `polished` and `changes`.
- Explain returns `meaning`, `tone`, `hiddenMeaning`, and `suggestedReplies`.
- No response contains an OpenAI exception, request ID, API key, or raw provider message.

These calls consume the configured free usage for the smoke-test identity.

## 9. Logs and troubleshooting

Backend:

```bash
cd /home/ubuntu/apps/replywise/backend
docker compose ps
docker compose logs -f --tail=200 api
docker compose logs --tail=200 postgres
docker compose restart api
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
sudo ss -ltnp | grep -E ':8000|:80|:443'
sudo ufw status verbose
```

Common failures:

- Startup validation error: check required `.env` variables and ensure both local-only flags are false.
- Migration error: inspect `docker compose run --rm api alembic current` and
  `docker compose run --rm api alembic history`.
- `502` from Caddy: check `docker compose ps`, API logs, and
  `127.0.0.1:8000/health`.
- OpenAI `MODEL_CONFIGURATION_ERROR`: verify the VM-only key and model access.
- OpenAI `MODEL_UNAVAILABLE`/`MODEL_RATE_LIMITED`: inspect service status, outbound connectivity, and account limits; raw provider details are intentionally not returned to clients.
- PostgreSQL connection error: verify the `postgres` container is healthy and
  `POSTGRES_PASSWORD` matches the password encoded in the database URL.

## 10. Database backup

Create a compressed PostgreSQL dump:

```bash
cd /home/ubuntu/apps/replywise/backend
BACKUP="replywise-backup-$(date +%Y%m%d-%H%M%S).sql.gz"
docker compose exec -T postgres \
  pg_dump -U replywise -d replywise --no-owner --no-privileges | gzip > "$BACKUP"
ls -lh "$BACKUP"
```

Copy a backup off the VM from your workstation:

```bash
scp -i <SSH_KEY_PATH> ubuntu@<VM_HOST>:/home/ubuntu/apps/replywise/backend/replywise-backup-<DATE>.sql.gz .
```

## 11. Safe update

### Guarded deploy helper (recommended)

On the VM, after pulling the new code, use the guarded helper. It validates the
Compose config and prints the ordered plan by default (dry run), and only runs
the mutating steps — `postgres` up, `alembic upgrade head`, `api` up, health,
logs — when you pass `--run`:

```bash
cd /home/ubuntu/apps/replywise
git pull --ff-only origin main

scripts/check_prod_deploy.sh          # dry run: validate + print the plan
scripts/check_prod_deploy.sh --run    # execute the deploy sequence
```

### Legacy PowerShell redeploy (disabled until it supports Alembic)

Do not run the legacy redeploy script until it has been updated to build the
Compose image, apply Alembic migrations, and restart the API container:

```powershell
.\scripts\redeploy-backend-oracle.ps1
```

Before using this script again, verify that it has been updated for the Docker
Compose + Alembic deployment flow. A legacy systemd-based redeploy script must
not be used against this setup.

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
docker compose build api
docker compose up -d postgres
docker compose run --rm api alembic upgrade head
docker compose up -d api
docker compose ps
curl --fail --silent --show-error http://127.0.0.1:8000/health
curl --fail --silent --show-error https://api-reply.novaaistudio.ca/health
```

The `.env` is gitignored, and PostgreSQL data survives in the named volume.

## 12. Rollback

Before updating, record the current commit and create a PostgreSQL backup:

```bash
cd /home/ubuntu/apps/replywise
git rev-parse HEAD
cd backend
docker compose exec -T postgres \
  pg_dump -U replywise -d replywise --no-owner --no-privileges \
  | gzip > "replywise-pre-rollback-$(date +%Y%m%d-%H%M%S).sql.gz"
```

To roll back code, replace `<KNOWN_GOOD_COMMIT>`:

```bash
cd /home/ubuntu/apps/replywise
git status --short
git checkout <KNOWN_GOOD_COMMIT>

cd backend
docker compose build api
docker compose run --rm api alembic upgrade head
docker compose up -d api
curl --fail --silent --show-error https://api-reply.novaaistudio.ca/health
```

Return to the deployment branch later with:

```bash
cd /home/ubuntu/apps/replywise
git checkout main
git pull --ff-only origin main
```

Code rollback does not automatically downgrade the database. Only run
`alembic downgrade` when the target revision and data-loss implications have
been reviewed and tested. Do not restore an older dump unless compatibility
requires it and the restore has been rehearsed.

## 13. Pre-Google-Play manual checklist

- DNS resolves to the Oracle VM.
- Caddy has a valid certificate and public `/health` succeeds.
- Production `.env` contains unique JWT/pepper values and VM-only OpenAI/RevenueCat secrets.
- Existing RevenueCat entitlement and product identifiers are verified unchanged.
- `REVENUECAT_SECRET_API_KEY` is a **v2-compatible** key (v1 keys return HTTP 403 on v2 endpoints).
- `REVENUECAT_PROJECT_ID` is set to the project ID from the RevenueCat dashboard → Project Settings.
- `REVENUECAT_WEBHOOK_SECRET` is set, and the RevenueCat webhook (section 7) points to `…/v1/webhooks/revenuecat` with the Authorization header set to the **raw secret value (no `Bearer` prefix)** and the recommended events enabled.
- `docker compose run --rm api alembic current` reports the expected head revision.
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
