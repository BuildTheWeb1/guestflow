#!/usr/bin/env bash
# =============================================================================
# GuestFlow — Pre-Demo End-to-End Test Checklist
# =============================================================================
# Usage: ./scripts/test-checklist.sh
#
# Run this script 15-30 minutes before every demo meeting.
# It checks all automated systems and prints a clear PASS/FAIL for each item.
#
# Prerequisites: startup.sh must have been run first (stack must be running).
# =============================================================================

set -uo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Helpers ───────────────────────────────────────────────────────────────────
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass()  { echo -e "  ${GREEN}[PASS]${RESET}  $1"; ((PASS_COUNT++)); }
fail()  { echo -e "  ${RED}[FAIL]${RESET}  $1"; ((FAIL_COUNT++)); }
warn()  { echo -e "  ${YELLOW}[WARN]${RESET}  $1"; ((WARN_COUNT++)); }
info()  { echo -e "  ${BLUE}[INFO]${RESET}  $1"; }
step()  { echo -e "\n${BOLD}$1${RESET}"; }

# ── Load .env ─────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ ! -f "${PROJECT_ROOT}/.env" ]]; then
    echo -e "${RED}ERROR: .env not found. Run startup.sh first.${RESET}"
    exit 1
fi

set -a
# shellcheck disable=SC1091
source "${PROJECT_ROOT}/.env"
set +a

echo ""
echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}${BLUE}  GuestFlow — Pre-Demo Test Checklist${RESET}"
echo -e "${BOLD}${BLUE}  $(date '+%Y-%m-%d %H:%M:%S %Z')${RESET}"
echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════${RESET}"

# =============================================================================
# CHECK 1 — Docker containers running
# =============================================================================
step "1. Docker containers"

cd "${PROJECT_ROOT}"

POSTGRES_STATUS=$(docker compose ps postgres --format "{{.Status}}" 2>/dev/null | head -1 || echo "not_found")
N8N_STATUS=$(docker compose ps n8n --format "{{.Status}}" 2>/dev/null | head -1 || echo "not_found")

if [[ "${POSTGRES_STATUS}" == *"healthy"* ]]; then
    pass "postgres container: healthy"
elif [[ "${POSTGRES_STATUS}" == *"running"* ]]; then
    warn "postgres container: running (healthcheck not confirmed yet)"
else
    fail "postgres container: ${POSTGRES_STATUS} — run: docker compose up -d"
fi

if [[ "${N8N_STATUS}" == *"running"* ]]; then
    pass "n8n container: running"
elif [[ "${N8N_STATUS}" == "not_found" || -z "${N8N_STATUS}" ]]; then
    fail "n8n container: not running — run: docker compose up -d"
else
    fail "n8n container: ${N8N_STATUS}"
fi

# =============================================================================
# CHECK 2 — n8n HTTP reachability
# =============================================================================
step "2. n8n local accessibility"

N8N_HTTP=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://localhost:5678" 2>/dev/null || echo "000")
if [[ "${N8N_HTTP}" =~ ^(200|302|401)$ ]]; then
    pass "n8n at http://localhost:5678 → HTTP ${N8N_HTTP}"
else
    fail "n8n not responding at localhost:5678 (HTTP ${N8N_HTTP})"
    info "Try: docker compose logs n8n | tail -20"
fi

# API health endpoint
N8N_HEALTH=$(curl -s --max-time 5 "http://localhost:5678/healthz" 2>/dev/null || echo "")
if echo "${N8N_HEALTH}" | grep -qi "ok\|healthy\|status" 2>/dev/null; then
    pass "n8n /healthz endpoint OK"
else
    warn "n8n /healthz response unclear: ${N8N_HEALTH:0:50}"
fi

# =============================================================================
# CHECK 3 — ngrok tunnel
# =============================================================================
step "3. ngrok tunnel (public HTTPS)"

NGROK_DOMAIN="${NGROK_STATIC_DOMAIN:-your-static-domain.ngrok-free.app}"

if [[ "${NGROK_DOMAIN}" == "your-static-domain.ngrok-free.app" ]]; then
    fail "NGROK_STATIC_DOMAIN is still placeholder — update .env"
else
    NGROK_HTTP=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://${NGROK_DOMAIN}/healthz" 2>/dev/null || echo "000")
    if [[ "${NGROK_HTTP}" =~ ^(200|302|401)$ ]]; then
        pass "ngrok tunnel: https://${NGROK_DOMAIN} → HTTP ${NGROK_HTTP}"
    elif [[ "${NGROK_HTTP}" == "000" ]]; then
        fail "ngrok tunnel unreachable (connection refused/timeout)"
        info "Start ngrok: ngrok http --domain=${NGROK_DOMAIN} 5678"
    else
        warn "ngrok tunnel returned HTTP ${NGROK_HTTP} — may still be starting"
    fi
fi

# =============================================================================
# CHECK 4 — Environment variables populated
# =============================================================================
step "4. Environment variables"

check_env_var() {
    local var_name="$1"
    local placeholder="$2"
    local value="${!var_name:-}"

    if [[ -z "${value}" ]]; then
        fail "${var_name}: not set"
    elif [[ "${value}" == "${placeholder}" ]]; then
        warn "${var_name}: still has placeholder value"
    else
        pass "${var_name}: set (${#value} chars)"
    fi
}

check_env_var "ANTHROPIC_API_KEY"          "sk-ant-api03-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
check_env_var "SUPABASE_URL"               "https://xxxxxxxxxxxxxxxxxxxx.supabase.co"
check_env_var "SUPABASE_SERVICE_ROLE_KEY"  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.xxxxxxxxxxxxxxxxxxxx"
check_env_var "META_VERIFY_TOKEN"          ""
check_env_var "META_APP_SECRET"            "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
check_env_var "OWNER_WA_NUMBER"            "40XXXXXXXXXX"
check_env_var "OWNER_PHONE_NUMBER_ID"      "YOUR_META_PHONE_NUMBER_ID"
check_env_var "META_OWNER_ACCESS_TOKEN"    "YOUR_META_ACCESS_TOKEN"

# N8N_ENCRYPTION_KEY length check
if [[ "${#N8N_ENCRYPTION_KEY}" -eq 32 ]]; then
    pass "N8N_ENCRYPTION_KEY: 32 characters (correct)"
else
    fail "N8N_ENCRYPTION_KEY: ${#N8N_ENCRYPTION_KEY} characters (must be 32)"
fi

# =============================================================================
# CHECK 5 — Claude API connectivity
# =============================================================================
step "5. Claude API (Anthropic)"

ANTHROPIC_KEY="${ANTHROPIC_API_KEY:-}"
if [[ -z "${ANTHROPIC_KEY}" || "${ANTHROPIC_KEY}" == "sk-ant-api03-xxx"* ]]; then
    warn "Skipping Claude API test — key not set or is placeholder"
else
    CLAUDE_RESPONSE=$(curl -s --max-time 15 \
        -H "x-api-key: ${ANTHROPIC_KEY}" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d '{"model":"claude-haiku-4-5","max_tokens":10,"messages":[{"role":"user","content":"Reply with the single word: OK"}]}' \
        "https://api.anthropic.com/v1/messages" 2>/dev/null || echo "")

    if echo "${CLAUDE_RESPONSE}" | grep -q '"type":"message"' 2>/dev/null; then
        pass "Claude API: responding (model claude-haiku-4-5)"
    elif echo "${CLAUDE_RESPONSE}" | grep -q '"error"' 2>/dev/null; then
        ERROR_MSG=$(echo "${CLAUDE_RESPONSE}" | grep -o '"message":"[^"]*"' | head -1 || echo "unknown error")
        fail "Claude API error: ${ERROR_MSG}"
    else
        warn "Claude API: unexpected response — ${CLAUDE_RESPONSE:0:80}"
    fi
fi

# =============================================================================
# CHECK 6 — Supabase connectivity
# =============================================================================
step "6. Supabase database"

SUPA_URL="${SUPABASE_URL:-}"
SUPA_KEY="${SUPABASE_SERVICE_ROLE_KEY:-}"

if [[ -z "${SUPA_URL}" || "${SUPA_URL}" == "https://xxxxxxxxxxxxxxxxxxxx.supabase.co" ]]; then
    warn "Skipping Supabase test — URL not set or is placeholder"
else
    SUPA_RESPONSE=$(curl -s --max-time 10 \
        -H "apikey: ${SUPA_KEY}" \
        -H "Authorization: Bearer ${SUPA_KEY}" \
        "${SUPA_URL}/rest/v1/clients?select=id,hotel_name,is_active&limit=5" 2>/dev/null || echo "")

    if echo "${SUPA_RESPONSE}" | grep -q '\[' 2>/dev/null; then
        CLIENT_COUNT=$(echo "${SUPA_RESPONSE}" | grep -o '"hotel_name"' | wc -l | tr -d ' ')
        pass "Supabase: connected — ${CLIENT_COUNT} client row(s) in clients table"

        # Check Stejarul row exists
        if echo "${SUPA_RESPONSE}" | grep -q "Stejarul" 2>/dev/null; then
            pass "Supabase: Pensiunea Stejarul row found"
        else
            warn "Supabase: Pensiunea Stejarul row NOT found — run supabase/seed.sql"
        fi

        # Check is_active
        if echo "${SUPA_RESPONSE}" | grep -q '"is_active":true' 2>/dev/null; then
            pass "Supabase: client is_active = true"
        else
            warn "Supabase: no active clients found — verify clients table"
        fi
    elif echo "${SUPA_RESPONSE}" | grep -q '"code"' 2>/dev/null; then
        ERROR_MSG=$(echo "${SUPA_RESPONSE}" | grep -o '"message":"[^"]*"' | head -1 || echo "auth error")
        fail "Supabase: ${ERROR_MSG} — check SUPABASE_SERVICE_ROLE_KEY"
    else
        warn "Supabase: unexpected response — ${SUPA_RESPONSE:0:80}"
        info "Have you run supabase/schema.sql and supabase/seed.sql?"
    fi
fi

# =============================================================================
# CHECK 7 — n8n workflow files
# =============================================================================
step "7. n8n workflow JSON files"

WORKFLOW_FILES=(
    "workflows/whatsapp-booking-bot.json"
    "workflows/google-review-responder.json"
    "workflows/social-media-generator.json"
)

for wf in "${WORKFLOW_FILES[@]}"; do
    if [[ -f "${PROJECT_ROOT}/${wf}" ]]; then
        # Validate JSON syntax
        if python3 -c "import sys,json; json.load(open('${PROJECT_ROOT}/${wf}'))" 2>/dev/null; then
            WF_NAME=$(python3 -c "import json; d=json.load(open('${PROJECT_ROOT}/${wf}')); print(d.get('name','?'))" 2>/dev/null || echo "?")
            pass "${wf}: valid JSON — \"${WF_NAME}\""
        else
            fail "${wf}: invalid JSON — file may be corrupted"
        fi
    else
        fail "${wf}: file not found"
    fi
done

# =============================================================================
# CHECK 8 — n8n workflow active status (via API)
# =============================================================================
step "8. n8n workflows active"

N8N_API="http://localhost:5678/api/v1/workflows"
N8N_WORKFLOWS=$(curl -s --max-time 5 \
    -H "Accept: application/json" \
    "${N8N_API}?limit=10" 2>/dev/null || echo "")

if echo "${N8N_WORKFLOWS}" | grep -q '"data"' 2>/dev/null; then
    ACTIVE_COUNT=$(echo "${N8N_WORKFLOWS}" | grep -o '"active":true' | wc -l | tr -d ' ')
    TOTAL_COUNT=$(echo "${N8N_WORKFLOWS}" | grep -o '"active":' | wc -l | tr -d ' ')

    if [[ "${TOTAL_COUNT}" -eq 0 ]]; then
        warn "No workflows found in n8n — import the JSON files from ./workflows/"
        info "In n8n: Settings → Import → select each .json file"
    else
        info "Found ${TOTAL_COUNT} workflow(s) in n8n, ${ACTIVE_COUNT} active"
        if [[ "${ACTIVE_COUNT}" -ge 1 ]]; then
            pass "At least 1 workflow is active"
        else
            warn "No workflows are active — toggle Workflow 1 (WhatsApp Booking Bot) ON"
        fi
    fi
else
    warn "Cannot query n8n API — n8n may still be starting or API auth required"
    info "Manually verify at: http://localhost:5678"
fi

# =============================================================================
# CHECK 9 — Demo content readiness
# =============================================================================
step "9. Demo content readiness"

# Check pre-generated review responses in prompts/
if [[ -f "${PROJECT_ROOT}/prompts/review-responder.md" ]]; then
    SAMPLE_COUNT=$(grep -c "^###" "${PROJECT_ROOT}/prompts/review-responder.md" 2>/dev/null || echo 0)
    pass "review-responder.md: present (${SAMPLE_COUNT} sample sections)"
else
    warn "prompts/review-responder.md not found"
fi

if [[ -f "${PROJECT_ROOT}/prompts/hotel-booking-bot.md" ]]; then
    pass "hotel-booking-bot.md: present"
else
    warn "prompts/hotel-booking-bot.md not found"
fi

if [[ -f "${PROJECT_ROOT}/prompts/social-media-generator.md" ]]; then
    pass "social-media-generator.md: present"
else
    warn "prompts/social-media-generator.md not found"
fi

# =============================================================================
# SUMMARY
# =============================================================================
echo ""
echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}  Test Summary${RESET}"
echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════${RESET}"
echo ""
echo -e "  ${GREEN}PASS: ${PASS_COUNT}${RESET}   ${RED}FAIL: ${FAIL_COUNT}${RESET}   ${YELLOW}WARN: ${WARN_COUNT}${RESET}"
echo ""

if [[ "${FAIL_COUNT}" -eq 0 && "${WARN_COUNT}" -eq 0 ]]; then
    echo -e "  ${GREEN}${BOLD}All checks passed. Ready for demo!${RESET}"
elif [[ "${FAIL_COUNT}" -eq 0 ]]; then
    echo -e "  ${YELLOW}${BOLD}No failures, but review the warnings above.${RESET}"
    echo -e "  ${YELLOW}The demo will likely work but verify the WARN items.${RESET}"
else
    echo -e "  ${RED}${BOLD}${FAIL_COUNT} check(s) failed. Fix before starting the demo.${RESET}"
fi

# =============================================================================
# QUICK REFERENCE CARD
# =============================================================================
echo ""
echo -e "${BOLD}  Quick Reference for Demo Day:${RESET}"
echo ""
echo -e "  n8n UI:        ${BLUE}http://localhost:5678${RESET}"
echo -e "  ngrok tunnel:  ${BLUE}https://${NGROK_STATIC_DOMAIN:-your-domain.ngrok-free.app}${RESET}"
echo -e "  WhatsApp hook: ${BLUE}https://${NGROK_STATIC_DOMAIN:-your-domain.ngrok-free.app}/webhook/whatsapp-inbound${RESET}"
echo -e "  DB (Supabase): ${BLUE}${SUPABASE_URL:-not set}${RESET}"
echo ""
echo -e "${BOLD}  To show live WhatsApp bot:${RESET}"
echo -e "  Send a WhatsApp message to the Meta test number from your phone."
echo -e "  Reply should arrive within 3-5 seconds from Claude."
echo ""
echo -e "${BOLD}  To demo Social Media Generator:${RESET}"
echo -e "  In n8n → Open Workflow 3 → Click 'Execute Workflow'"
echo -e "  Check owner WhatsApp for 3 posts within 10 seconds."
echo ""
echo -e "${BOLD}  To demo Review Responder:${RESET}"
echo -e "  In n8n → Open Workflow 2 → Click 'Execute Workflow'"
echo -e "  The demo review (Andrei Popescu, 4 stars) will be processed."
echo ""
echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════${RESET}"
echo ""

# Exit with failure code if any checks failed
if [[ "${FAIL_COUNT}" -gt 0 ]]; then
    exit 1
fi
exit 0
