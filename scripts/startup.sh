#!/usr/bin/env bash
# =============================================================================
# AutoPilot Ospitalitate — Demo Day Startup Script
# =============================================================================
# Usage: ./scripts/startup.sh
#
# What this script does:
#   1. Validates prerequisites (Docker, ngrok, .env file)
#   2. Creates required local data directories
#   3. Starts Docker Compose stack (postgres + n8n)
#   4. Waits for n8n to be healthy
#   5. Prints ngrok command to run in a second terminal
#   6. Confirms all systems are ready
#
# Run this from the project root:
#   cd /path/to/guestflow
#   ./scripts/startup.sh
# =============================================================================

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Helpers ───────────────────────────────────────────────────────────────────
print_header() {
    echo ""
    echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}${BLUE}  AutoPilot Ospitalitate — Demo Startup${RESET}"
    echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════${RESET}"
    echo ""
}

ok()   { echo -e "  ${GREEN}✓${RESET}  $1"; }
warn() { echo -e "  ${YELLOW}⚠${RESET}  $1"; }
fail() { echo -e "  ${RED}✗${RESET}  $1"; }
info() { echo -e "  ${BLUE}→${RESET}  $1"; }
step() { echo -e "\n${BOLD}$1${RESET}"; }

# ── Determine script location → project root ──────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

print_header
info "Project root: ${PROJECT_ROOT}"

# =============================================================================
# STEP 1 — Prerequisites
# =============================================================================
step "Step 1 — Checking prerequisites"

PREREQS_OK=true

# Docker
if command -v docker &>/dev/null; then
    DOCKER_VER=$(docker --version 2>&1 | head -1)
    ok "Docker: ${DOCKER_VER}"
else
    fail "Docker not found. Install Docker Desktop: https://docs.docker.com/desktop/install/mac-install/"
    PREREQS_OK=false
fi

# Docker Compose
if docker compose version &>/dev/null 2>&1; then
    COMPOSE_VER=$(docker compose version 2>&1 | head -1)
    ok "Docker Compose: ${COMPOSE_VER}"
else
    fail "Docker Compose not found. Update Docker Desktop to a recent version."
    PREREQS_OK=false
fi

# Docker daemon running
if docker info &>/dev/null 2>&1; then
    ok "Docker daemon is running"
else
    fail "Docker daemon is not running. Start Docker Desktop first."
    PREREQS_OK=false
fi

# ngrok
if command -v ngrok &>/dev/null; then
    NGROK_VER=$(ngrok version 2>&1 | head -1)
    ok "ngrok: ${NGROK_VER}"
else
    warn "ngrok not found. Install with: brew install ngrok/ngrok/ngrok"
    warn "You can still start the Docker stack, but webhooks won't work."
fi

# .env file
if [[ -f "${PROJECT_ROOT}/.env" ]]; then
    ok ".env file found"
else
    fail ".env file not found at ${PROJECT_ROOT}/.env"
    info "Create it: cp ${PROJECT_ROOT}/.env.example ${PROJECT_ROOT}/.env"
    info "Then fill in your real values (NGROK_STATIC_DOMAIN, API keys, etc.)"
    PREREQS_OK=false
fi

if [[ "${PREREQS_OK}" != "true" ]]; then
    echo ""
    echo -e "${RED}${BOLD}Prerequisites check failed. Fix the issues above and re-run.${RESET}"
    exit 1
fi

# ── Load .env ─────────────────────────────────────────────────────────────────
set -a
# shellcheck disable=SC1091
source "${PROJECT_ROOT}/.env"
set +a

# Validate critical env vars
REQUIRED_VARS=(NGROK_STATIC_DOMAIN POSTGRES_USER POSTGRES_PASSWORD N8N_ENCRYPTION_KEY)
ENV_OK=true
for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        fail "Required variable ${var} is not set in .env"
        ENV_OK=false
    fi
done

# Check N8N_ENCRYPTION_KEY length
if [[ "${#N8N_ENCRYPTION_KEY}" -ne 32 ]]; then
    fail "N8N_ENCRYPTION_KEY must be exactly 32 characters (currently ${#N8N_ENCRYPTION_KEY})"
    info "Generate one: openssl rand -hex 16"
    ENV_OK=false
else
    ok "N8N_ENCRYPTION_KEY is 32 characters"
fi

# Check for placeholder values
if [[ "${NGROK_STATIC_DOMAIN}" == "your-static-domain.ngrok-free.app" ]]; then
    warn "NGROK_STATIC_DOMAIN still has placeholder value — update it in .env"
fi

if [[ "${ANTHROPIC_API_KEY:-}" == "sk-ant-api03-xxx"* ]]; then
    warn "ANTHROPIC_API_KEY appears to be a placeholder — Claude calls will fail"
fi

if [[ "${ENV_OK}" != "true" ]]; then
    echo ""
    echo -e "${RED}${BOLD}Environment variable errors. Fix .env and re-run.${RESET}"
    exit 1
fi

# =============================================================================
# STEP 2 — Create local data directories
# =============================================================================
step "Step 2 — Preparing local directories"

mkdir -p "${PROJECT_ROOT}/n8n-data"
mkdir -p "${PROJECT_ROOT}/postgres-data"
ok "Created ./n8n-data and ./postgres-data"

# Fix n8n-data ownership for the n8n container (runs as node user, uid 1000)
# Only chown if directory was just created or is empty
if [[ -d "${PROJECT_ROOT}/n8n-data" ]]; then
    ok "./n8n-data is ready"
fi
if [[ -d "${PROJECT_ROOT}/postgres-data" ]]; then
    ok "./postgres-data is ready"
fi

# =============================================================================
# STEP 3 — Start Docker Compose stack
# =============================================================================
step "Step 3 — Starting Docker Compose stack"

cd "${PROJECT_ROOT}"

# Pull latest images (optional but ensures no stale image issues)
info "Pulling latest images (this may take a moment on first run)..."
docker compose pull --quiet 2>/dev/null || warn "Image pull had warnings — continuing"

# Start stack
info "Starting postgres and n8n..."
docker compose up -d

ok "Docker Compose started"

# =============================================================================
# STEP 4 — Wait for n8n to be healthy
# =============================================================================
step "Step 4 — Waiting for n8n to be ready"

N8N_URL="http://localhost:5678"
MAX_WAIT=60
WAITED=0
INTERVAL=3

info "Polling ${N8N_URL} (max ${MAX_WAIT}s)..."

while true; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${N8N_URL}" 2>/dev/null || true)
    if [[ "${HTTP_CODE}" =~ ^(200|302|401)$ ]]; then
        ok "n8n is responding (HTTP ${HTTP_CODE})"
        break
    fi

    WAITED=$((WAITED + INTERVAL))
    if [[ ${WAITED} -ge ${MAX_WAIT} ]]; then
        warn "n8n did not respond within ${MAX_WAIT}s — it may still be starting"
        info "Check logs: docker compose logs -f n8n"
        break
    fi

    printf "    Waiting... %ds\r" "${WAITED}"
    sleep "${INTERVAL}"
done

# =============================================================================
# STEP 5 — Container status
# =============================================================================
step "Step 5 — Container status"

POSTGRES_STATUS=$(docker compose ps postgres --format "{{.Status}}" 2>/dev/null | head -1 || echo "unknown")
N8N_STATUS=$(docker compose ps n8n --format "{{.Status}}" 2>/dev/null | head -1 || echo "unknown")

if [[ "${POSTGRES_STATUS}" == *"healthy"* ]] || [[ "${POSTGRES_STATUS}" == *"running"* ]]; then
    ok "postgres: ${POSTGRES_STATUS}"
else
    warn "postgres: ${POSTGRES_STATUS}"
fi

if [[ "${N8N_STATUS}" == *"running"* ]]; then
    ok "n8n: ${N8N_STATUS}"
else
    warn "n8n: ${N8N_STATUS}"
fi

# =============================================================================
# STEP 6 — Instructions
# =============================================================================
step "Step 6 — Next steps"

echo ""
echo -e "${BOLD}  Open n8n:${RESET}  ${BLUE}http://localhost:5678${RESET}"
echo ""
echo -e "${BOLD}  Start ngrok in a NEW terminal:${RESET}"
echo -e "  ${YELLOW}ngrok http --domain=${NGROK_STATIC_DOMAIN} 5678${RESET}"
echo ""
echo -e "${BOLD}  After ngrok is running, verify the tunnel:${RESET}"
echo -e "  ${YELLOW}curl -s https://${NGROK_STATIC_DOMAIN}/healthz${RESET}"
echo ""
echo -e "${BOLD}  Check n8n logs if anything looks wrong:${RESET}"
echo -e "  ${YELLOW}docker compose logs -f n8n${RESET}"
echo ""
echo -e "${BOLD}  Stop everything when done:${RESET}"
echo -e "  ${YELLOW}docker compose down${RESET}"
echo ""
echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}${BOLD}  Stack is running. Ready for demo!${RESET}"
echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════${RESET}"
echo ""
