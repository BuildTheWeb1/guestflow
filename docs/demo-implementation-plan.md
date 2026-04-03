# GuestFlow — Demo Implementation Plan (Localhost)

**Goal:** Run the full demo stack on your local machine. No VPS, no domain purchase, no SSL config. External APIs (Claude, WhatsApp, Google, Supabase) are real — only the server moves to localhost.

---

## Architecture Differences vs. Production

| Component | Production | Demo |
|-----------|-----------|------|
| Server | Hetzner CX22 VPS | Your Mac/Linux machine |
| Reverse proxy | Traefik + Let's Encrypt | None |
| Public HTTPS URL | `n8n.autopilot-ospitalitate.ro` | ngrok static domain (free) |
| Queue backend | Redis | SQLite (n8n default, simpler) |
| n8n port | Internal only | `localhost:5678` (direct) |
| Docker volumes | `/opt/autopilot/...` | `~/autopilot-demo/...` |
| Claude API | Real | Real |
| WhatsApp API | Real Meta Cloud | Real Meta Cloud |
| Supabase | Real free tier | Real free tier |
| Google My Business | Real OAuth2 | Real OAuth2 |

The only thing that isn't "real" in the demo is the server location. Every API call, every WhatsApp message, every Claude response — all real.

---

## Prerequisites

Install these before starting:

```bash
# Docker Desktop (Mac) — https://docs.docker.com/desktop/install/mac-install/
# Verify:
docker --version
docker compose version

# ngrok — https://ngrok.com/download
brew install ngrok/ngrok/ngrok

# Log in to ngrok (free account at ngrok.com)
ngrok config add-authtoken <YOUR_NGROK_TOKEN>
```

You'll need accounts/keys for:
- [ngrok.com](https://ngrok.com) — free account, claim your free static domain
- [Anthropic Console](https://console.anthropic.com) — Claude API key
- [Meta Developer](https://developers.facebook.com) — WhatsApp Cloud API app
- [Supabase](https://supabase.com) — free project
- [Google Cloud Console](https://console.cloud.google.com) — for Google My Business API (Workflow 2 only)

---

## Step 1: Directory Setup

```bash
mkdir -p ~/autopilot-demo/{n8n-data,postgres-data}
cd ~/autopilot-demo
```

---

## Step 2: Docker Compose (Simplified — No Traefik, No Redis)

Create `~/autopilot-demo/docker-compose.yml`:

```yaml
version: '3.8'

networks:
  autopilot-net:
    driver: bridge

volumes:
  n8n_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ./n8n-data
  postgres_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ./postgres-data

services:

  postgres:
    image: postgres:15-alpine
    container_name: autopilot-postgres
    restart: unless-stopped
    networks:
      - autopilot-net
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: n8n
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  n8n:
    image: n8nio/n8n:latest
    container_name: autopilot-n8n
    restart: unless-stopped
    networks:
      - autopilot-net
    depends_on:
      postgres:
        condition: service_healthy
    ports:
      - "5678:5678"       # Exposed directly on localhost — no Traefik needed
    environment:
      # Database
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=${POSTGRES_USER}
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}
      # n8n Core — WEBHOOK_URL points to your ngrok static domain
      - N8N_HOST=localhost
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=https://${NGROK_STATIC_DOMAIN}/
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      # No basic auth for local dev (add if sharing screen with others)
      - N8N_BASIC_AUTH_ACTIVE=false
      # Timezone
      - GENERIC_TIMEZONE=Europe/Bucharest
      - TZ=Europe/Bucharest
      # Keep execution logs for debugging
      - EXECUTIONS_DATA_SAVE_ON_ERROR=all
      - EXECUTIONS_DATA_SAVE_ON_SUCCESS=all
      - EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS=true
    volumes:
      - n8n_data:/home/node/.n8n
```

> **Why no Redis?** Without `EXECUTIONS_MODE=queue`, n8n runs in "regular" mode using its own process queue. Fine for demo load (1-5 concurrent workflows). Add Redis only when going to production.

---

## Step 3: .env File

Create `~/autopilot-demo/.env`:

```bash
# ngrok — your free static domain (e.g. fox-happy-lion.ngrok-free.app)
NGROK_STATIC_DOMAIN=your-static-domain.ngrok-free.app

# PostgreSQL
POSTGRES_USER=n8n_user
POSTGRES_PASSWORD=changeme_local_only

# n8n
N8N_ENCRYPTION_KEY=demo_key_32chars_changeme_local1

# Claude API
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Supabase
SUPABASE_URL=https://xxxxxxxxxxxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJxxxxxxxxxxxxxxxxxxxxxxxxxx

# Meta / WhatsApp
META_APP_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
META_VERIFY_TOKEN=my-demo-verify-token-123
```

> Passwords here are for local use only. They never leave your machine. Don't reuse them in production.

---

## Step 4: Get a Free ngrok Static Domain

ngrok free accounts include one static domain (no expiry, no token rotation):

```bash
# After installing and logging in:
ngrok http --domain=your-static-domain.ngrok-free.app 5678
```

To claim your domain: go to [dashboard.ngrok.com](https://dashboard.ngrok.com) → Domains → New Domain → copy the assigned static hostname.

This domain is permanent. You'll register it once in Meta's webhook config and Google Cloud and never have to update it again (as long as you keep the ngrok tunnel running during demos).

---

## Step 5: Start Everything

Terminal 1 — Docker stack:
```bash
cd ~/autopilot-demo
docker compose up -d
docker compose logs -f n8n   # watch for startup errors
```

Terminal 2 — ngrok tunnel:
```bash
ngrok http --domain=your-static-domain.ngrok-free.app 5678
```

Verify:
- n8n UI: [http://localhost:5678](http://localhost:5678)
- Webhook reachable: `curl https://your-static-domain.ngrok-free.app/healthz` → should return 200

---

## Step 6: Supabase Schema

Create a free project at [supabase.com](https://supabase.com). In the SQL editor, run the schema from Section 8 of the technical implementation plan (clients, conversations, messages, social_content, email_routing, audit_log tables).

Then insert the demo hotel row:

```sql
INSERT INTO clients (
  id,
  hotel_name,
  owner_name,
  owner_wa_number,
  whatsapp_phone_number_id,
  wa_access_token,
  system_prompt,
  is_active,
  client_index
) VALUES (
  gen_random_uuid(),
  'Pensiunea Stejarul',
  'Demo Owner',
  '40XXXXXXXXXX',           -- your own WhatsApp number (receives all notifications)
  'YOUR_META_PHONE_NUMBER_ID',
  'YOUR_META_ACCESS_TOKEN',
  'Ești asistentul virtual al Pensiunii Stejarul din Sinaia.
Răspunzi în română, politicos și concis.
Camere: 6 duble (250 RON/noapte în săptămână, 350 RON weekend) + 1 apartament familie (450 RON/noapte, 600 RON weekend).
Mic dejun inclus, check-in 14:00, check-out 11:00.
Dacă oaspeții întreabă despre disponibilitate, spune că verifici și vei reveni în câteva minute.
Colectează: nume, dată check-in, dată check-out, număr persoane.
Nu fă rezervări definitive — transmite că proprietarul va confirma.',
  true,
  0
);
```

---

## Step 7: Meta WhatsApp Cloud API Setup

1. Go to [developers.facebook.com](https://developers.facebook.com) → Create App → Business
2. Add "WhatsApp" product to the app
3. In WhatsApp → Getting Started:
   - Copy the **Phone Number ID** and **Temporary Access Token** → paste into Supabase `clients` row and `.env`
   - Add a recipient number (your WhatsApp) to the test allowlist
4. In WhatsApp → Configuration → Webhook:
   - Callback URL: `https://your-static-domain.ngrok-free.app/webhook/whatsapp-inbound`
   - Verify token: value from `META_VERIFY_TOKEN` in your `.env`
   - Subscribe to: `messages`

> The temporary access token expires in 24 hours. For demos spread over multiple days, generate a permanent token via a System User in Meta Business Manager (Settings → System Users → Generate Token → WhatsApp product).

---

## Step 8: Build Workflows in n8n

Open [http://localhost:5678](http://localhost:5678). Build each workflow from Section 9 of the technical implementation plan, with these local adaptations:

### All Workflows — Credential Setup

In n8n Settings → Credentials, add:

| Credential Name | Type | Values |
|-----------------|------|--------|
| Claude API | HTTP Header Auth | Header: `x-api-key`, Value: your Anthropic key |
| Supabase | HTTP Header Auth | Header: `apikey`, Value: your service role key |
| Meta WhatsApp | HTTP Header Auth | Header: `Authorization`, Value: `Bearer <token>` |

Use these credentials in HTTP Request nodes instead of environment variable interpolation where n8n's credential picker is available.

### Workflow 1: WhatsApp Booking Bot

Build exactly as in Section 9.1. The only local difference:

- In the **Webhook Node**: n8n automatically uses `WEBHOOK_URL` (your ngrok domain) as the base. The full URL you register in Meta will be: `https://your-static-domain.ngrok-free.app/webhook/whatsapp-inbound`
- Test by sending a WhatsApp message to the Meta test number from your personal WhatsApp

### Workflow 2: Google Review Responder

Build as in Section 9.2. For local setup:

- Google Cloud Console → new project → enable "My Business Account Management API" and "My Business Reviews API"
- OAuth2 credentials → Desktop App type (easier than Web App for local testing — no redirect URI config needed)
- In n8n: use the Google OAuth2 credential type → it will open a browser tab to authorize

> For the demo, you can mock the review polling step by using a **Manual Trigger** instead of a Schedule, and hardcoding a sample review JSON. This lets you demo the approval flow without waiting for a real review to appear.

### Workflow 3: Social Media Generator

Build as in Section 9.3. For local testing, replace the Schedule trigger with a **Manual Trigger** so you can fire it on demand during a demo instead of waiting for Monday 09:00.

### Workflow 4: Email Router

Skip for the demo. Mention it exists but don't build or show it. (Low visual impact, adds setup complexity.)

---

## Step 9: End-to-End Test Checklist

Run through this before every demo meeting:

```
[ ] docker compose up -d  (containers running)
[ ] ngrok tunnel live: https://your-static-domain.ngrok-free.app
[ ] n8n accessible at localhost:5678
[ ] Workflow 1 active (toggle ON in n8n)
[ ] Send test WhatsApp to Meta number → receive Claude reply within 5 seconds
[ ] Workflow 3 manual trigger → receive 3 social posts on your WhatsApp
[ ] Supabase clients table has Stejarul row with is_active=true
[ ] Pre-generated review responses ready (3x, from real Sinaia hotels)
[ ] Prospect-specific review responses prepared (15 min before meeting)
```

---

## Step 10: Demo Day Startup Sequence

When you sit down to do a demo:

```bash
# Terminal 1
cd ~/autopilot-demo && docker compose up -d

# Terminal 2
ngrok http --domain=your-static-domain.ngrok-free.app 5678

# Wait ~20 seconds, then verify:
curl -s https://your-static-domain.ngrok-free.app/healthz
# Open localhost:5678 and check Workflow 1 is active
```

Keep Terminal 2 (ngrok) visible but minimized. If the prospect asks what it is, say "acesta e tunelul securizat care conectează demonstrația cu serverele Meta și Google."

---

## Upgrading to Production

When you get paying clients, the migration is a single afternoon:

1. Provision Hetzner CX22 → run VPS bootstrap from the technical implementation plan
2. Copy `~/autopilot-demo/n8n-data/` to VPS (preserves all workflows and credentials)
3. Update `WEBHOOK_URL` from ngrok domain to your real domain
4. Update Meta webhook URL in developers.facebook.com
5. Add Traefik + Redis to `docker-compose.yml` (from the production plan)
6. Done — client data stays in Supabase (already cloud), workflows are identical

Zero rebuilding. The demo stack IS the production stack, minus the server.
