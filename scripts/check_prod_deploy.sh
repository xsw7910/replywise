#!/usr/bin/env bash
#
# check_prod_deploy.sh — safe production deploy reminder / checker for the
# ReplyWise backend (Docker Compose + PostgreSQL + Alembic).
#
# Production does NOT auto-create tables (Base.metadata.create_all runs only in
# dev/test), so migrations MUST be applied before the API starts. This script
# validates the Compose config and prints the exact ordered deploy commands.
#
# By default it is a DRY RUN: it only runs read-only checks and prints the plan.
# Pass --run to actually execute the mutating steps (postgres up, migrate, api up).
#
# Usage:
#   scripts/check_prod_deploy.sh            # dry run: validate + print plan
#   scripts/check_prod_deploy.sh --run      # execute the deploy sequence
#
# This script never prints secrets.

set -euo pipefail

RUN=0
for arg in "$@"; do
  case "$arg" in
    --run) RUN=1 ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "Unknown argument: $arg" >&2; exit 2 ;;
  esac
done

# Resolve the backend directory relative to this script (repo/scripts/..).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/../backend" && pwd)"
cd "$BACKEND_DIR"

HEALTH_URL="${HEALTH_URL:-http://localhost:8000/health}"

info()  { printf '\033[36m[check]\033[0m %s\n' "$*"; }
warn()  { printf '\033[33m[warn]\033[0m %s\n' "$*"; }
ok()    { printf '\033[32m[ok]\033[0m %s\n' "$*"; }
fail()  { printf '\033[31m[fail]\033[0m %s\n' "$*" >&2; }

command -v docker >/dev/null 2>&1 || { fail "docker CLI not found on this host."; exit 1; }

info "Backend directory: $BACKEND_DIR"

# 1) .env presence (contents are never printed).
if [[ -f .env ]]; then
  ok ".env present"
  # Remind about required keys without revealing values.
  REQUIRED=(REPLY_ENV POSTGRES_PASSWORD JWT_SECRET SERVER_PEPPER OPENAI_API_KEY \
            REVENUECAT_SECRET_API_KEY REVENUECAT_WEBHOOK_SECRET REVENUECAT_PROJECT_ID \
            REVENUECAT_ENTITLEMENT_ID REVENUECAT_SUBSCRIPTION_PRODUCT_ID \
            REVENUECAT_CREDIT_PRODUCT_MAP MOCK_AI_ENABLED DEV_TOOLS_ENABLED)
  missing=()
  for key in "${REQUIRED[@]}"; do
    # present-and-non-empty check: match "KEY=<something>"
    grep -qE "^${key}=..*" .env || missing+=("$key")
  done
  if ((${#missing[@]})); then
    warn "These required keys look empty/absent in .env: ${missing[*]}"
    warn "REPLY_ENV=prod will fail to start until every required secret is set."
  else
    ok "All required .env keys are present and non-empty"
  fi
else
  warn ".env not found in $BACKEND_DIR — create it before deploying (see docs/ORACLE_VM_BACKEND_DEPLOYMENT.md §4)."
fi

# 2) Read-only: validate the rendered Compose configuration.
info "Validating docker compose config (read-only)…"
if docker compose config >/dev/null 2>err.log; then
  ok "docker compose config is valid"
else
  fail "docker compose config failed:"; cat err.log >&2; rm -f err.log; exit 1
fi
rm -f err.log

cat <<'PLAN'

──────────────────────────────────────────────────────────────────
Production deploy sequence (run from backend/):

  docker compose build api
  docker compose up -d postgres
  docker compose run --rm api alembic upgrade head   # REQUIRED: prod has no auto-create
  docker compose up -d api
  curl -fsS http://localhost:8000/health
  docker compose logs --tail=30 api

Reminders:
  • REPLY_ENV=prod rejects SQLite and does NOT create tables automatically.
  • Configure the RevenueCat webhook -> https://<domain>/v1/webhooks/revenuecat
    with the Authorization value equal to REVENUECAT_WEBHOOK_SECRET.
──────────────────────────────────────────────────────────────────

PLAN

if [[ "$RUN" -eq 0 ]]; then
  info "Dry run complete. Re-run with --run to execute the sequence above."
  exit 0
fi

# 3) --run: execute the mutating deploy steps.
info "Executing deploy sequence…"
docker compose build api
docker compose up -d postgres
info "Applying Alembic migrations…"
docker compose run --rm api alembic upgrade head
docker compose up -d api

info "Health check: $HEALTH_URL"
if curl -fsS "$HEALTH_URL" >/dev/null; then
  ok "Health check passed"
else
  fail "Health check failed — inspect: docker compose logs --tail=50 api"
  exit 1
fi

docker compose logs --tail=30 api
ok "Deploy sequence finished. Verify alembic revision: docker compose run --rm api alembic current"
