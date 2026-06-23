#!/usr/bin/env bash
# =============================================================================
# Finder Backend — EC2 Deployment Script
# Run from your LOCAL Mac, not on the server.
#
# Usage:
#   chmod +x scripts/deploy.sh
#   ./scripts/deploy.sh
# =============================================================================

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
KEY="${KEY:-$HOME/Documents/newttesst.pem}"
EC2_HOST="ec2-user@13.48.25.33"
REMOTE_DIR="/home/ec2-user/backend-service"
LOCAL_DIR="$(cd "$(dirname "$0")/.." && pwd)"  # backend-service/

echo "📦 Deploying Finder Backend to EC2"
echo "   Local  : $LOCAL_DIR"
echo "   Remote : $EC2_HOST:$REMOTE_DIR"
echo ""

# ── Step 1: Sync source files (exclude secrets and generated files) ────────────
echo "🔄 Syncing source files..."
rsync -avz --progress \
  --exclude='.env' \
  --exclude='node_modules/' \
  --exclude='lost_and_found.sqlite' \
  --exclude='test.sqlite' \
  --exclude='uploads/' \
  --exclude='*.log' \
  --exclude='.git/' \
  -e "ssh -i $KEY -o StrictHostKeyChecking=no" \
  "$LOCAL_DIR/" \
  "$EC2_HOST:$REMOTE_DIR/"
echo "✅ Files synced"
echo ""

# ── Step 2: Remote — install deps, setup PM2, restart ─────────────────────────
echo "🚀 Running remote setup..."
ssh -i "$KEY" -o StrictHostKeyChecking=no "$EC2_HOST" bash <<'REMOTE'
set -euo pipefail
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" || true
REMOTE_DIR="/home/ec2-user/backend-service"
LOG_DIR="/home/ec2-user/logs"

echo "📁 Ensuring directories exist..."
mkdir -p "$REMOTE_DIR" "$LOG_DIR"

echo "📦 Installing Node dependencies..."
cd "$REMOTE_DIR"
npm install --omit=dev

# ── Install PM2 globally if not present ────────────────────────────────────────
if ! command -v pm2 &>/dev/null; then
  echo "⚙️  Installing PM2..."
  npm install -g pm2
fi
echo "✅ PM2 version: $(pm2 --version)"

# ── Verify .env exists and has a real JWT_SECRET ───────────────────────────────
if [ ! -f "$REMOTE_DIR/.env" ]; then
  echo ""
  echo "❌ ERROR: $REMOTE_DIR/.env does not exist!"
  echo "   Create it from .env.example before deploying."
  echo "   At minimum, set: JWT_SECRET, DATABASE_URL, FIREBASE_SERVICE_ACCOUNT"
  exit 1
fi

if grep -q "REPLACE_WITH_STRONG_SECRET\|change-me-to" "$REMOTE_DIR/.env"; then
  echo ""
  echo "❌ ERROR: JWT_SECRET in .env is still the placeholder value!"
  echo "   Generate a real secret: openssl rand -hex 64"
  echo "   Then paste it into $REMOTE_DIR/.env"
  exit 1
fi

# ── Restart with PM2 ──────────────────────────────────────────────────────────
echo "🔄 Restarting server with PM2..."
cd "$REMOTE_DIR"
if pm2 describe finder-backend >/dev/null 2>&1; then
  pm2 reload ecosystem.config.js --env production --update-env
else
  pm2 start ecosystem.config.js --env production
fi

# ── Save PM2 process list + enable startup on reboot ─────────────────────────
pm2 save
pm2 startup | tail -1 | bash 2>/dev/null || true

echo ""
echo "✅ Deployment complete!"
echo ""

# ── Smoke test ────────────────────────────────────────────────────────────────
sleep 3
echo "🩺 Health check..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3500/api/v1/health 2>/dev/null || echo "FAILED")
if [ "$STATUS" = "200" ]; then
  echo "✅ Server is healthy (HTTP 200)"
else
  echo "❌ Health check returned: $STATUS"
  echo "   Check logs: pm2 logs finder-backend --lines 50"
  exit 1
fi

echo ""
pm2 list
REMOTE

echo ""
echo "🎉 Deployment complete! Admin routes audit:"
echo ""

# ── Step 3: Live route audit from local machine ────────────────────────────────
BASE="https://51.20.140.64.nip.io/api/v1"

TOKEN=$(curl -sf -X POST "$BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@finder.app","password":"Admin@1234!"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['token'])" 2>/dev/null || echo "")

if [ -z "$TOKEN" ]; then
  echo "⚠️  Could not obtain JWT — run login manually to verify routes"
else
  echo "JWT obtained (${#TOKEN} chars)"
  echo ""
  for route in stats users posts reports verifications "verifications/pending" "chats/test/messages"; do
    CODE=$(curl -sf -o /dev/null -w "%{http_code}" \
      -H "Authorization: Bearer $TOKEN" \
      "$BASE/admin/$route" 2>/dev/null || echo "ERR")
    ICON=$( [ "$CODE" = "200" ] || [ "$CODE" = "404" -a "$route" = "chats/test/messages" ] && echo "✅" || ([ "$CODE" = "404" ] && echo "❌" || echo "⚠️"))
    echo "  $ICON GET /admin/$route → $CODE"
  done
fi
