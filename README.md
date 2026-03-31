# GuestFlow — GuestFlow

AI automation for Romanian hotels and guesthouses. Three production-ready workflows built on n8n + Claude that handle guest communication, review management, and social media — so owners can focus on hospitality, not inbox management.

---

## What It Does

| Workflow | Description |
|----------|-------------|
| **WhatsApp Booking Bot** | Answers guest inquiries in Romanian via WhatsApp, 24/7. Claude responds using each hotel's specific room types, pricing, and policies stored in Supabase. |
| **Google Review Responder** | Generates personalized, branded responses to Google reviews (positive and negative). Drafts are ready to post — owner approves in seconds. |
| **Social Media Generator** | Produces batches of Facebook/Instagram captions tailored to the hotel's voice and current season. |

---

## Architecture

```
Guest (WhatsApp) ──► Meta Cloud API
                          │
                          ▼
              ngrok (public tunnel) ──► n8n (localhost:5678)
                                             │
                          ┌──────────────────┼──────────────────┐
                          ▼                  ▼                  ▼
                   Claude API          Supabase DB        Google My
                  (AI responses)    (client profiles)   Business API
```

**Local / Demo stack:**

- **n8n** — workflow automation engine (Docker)
- **PostgreSQL** — n8n internal database (Docker)
- **ngrok** — exposes localhost to the internet for Meta webhooks
- **Supabase** — guest and client data (cloud, free tier)
- **Claude (Anthropic)** — AI response generation
- **Meta WhatsApp Cloud API** — messaging

---

## Quick Start

### Prerequisites

```bash
# Docker Desktop
docker --version
docker compose version

# ngrok (free account at ngrok.com, claim a free static domain)
brew install ngrok/ngrok/ngrok
ngrok config add-authtoken <YOUR_NGROK_TOKEN>
```

You also need accounts/API keys for:
- [ngrok.com](https://ngrok.com) — free static domain
- [Anthropic Console](https://console.anthropic.com) — Claude API key
- [Meta Developer](https://developers.facebook.com) — WhatsApp Cloud API app
- [Supabase](https://supabase.com) — free project
- [Google Cloud Console](https://console.cloud.google.com) — Google My Business API (Workflow 2 only)

### 1. Clone & configure

```bash
git clone <repo-url>
cd guestflow
cp .env.example .env
# Edit .env with your real credentials
```

### 2. Create Docker volume directories

```bash
mkdir -p n8n-data postgres-data
```

### 3. Start the stack

```bash
docker compose up -d
```

n8n is now available at `http://localhost:5678`.

### 4. Start ngrok tunnel

```bash
ngrok http --domain=your-static-domain.ngrok-free.app 5678
```

### 5. Import workflows

In n8n → Settings → Import:
- `workflows/whatsapp-booking-bot.json`
- `workflows/google-review-responder.json`
- `workflows/social-media-generator.json`

### 6. Set up Supabase schema

Run the SQL files in order against your Supabase project:

```bash
# In Supabase SQL Editor:
# 1. supabase/schema.sql
# 2. supabase/seed.sql   (demo data — Pensiunea Stejarul)
```

---

## Project Structure

```
guestflow/
├── docker-compose.yml          # n8n + PostgreSQL stack
├── .env.example                # Environment variable template
├── workflows/
│   ├── whatsapp-booking-bot.json
│   ├── google-review-responder.json
│   └── social-media-generator.json
├── prompts/
│   ├── hotel-booking-bot.md    # System prompt for WhatsApp bot
│   ├── review-responder.md     # System prompt for review responses
│   └── social-media-generator.md
├── supabase/
│   ├── schema.sql              # Database schema
│   └── seed.sql                # Demo data (Pensiunea Stejarul)
├── scripts/
│   ├── startup.sh              # One-command demo startup
│   └── test-checklist.sh       # Pre-demo verification
└── docs/
    ├── demo-plan.md            # 20-minute demo script
    ├── demo-implementation-plan.md
    └── solopreneur-ai-automation-agency.md
```

---

## Environment Variables

Copy `.env.example` to `.env` and fill in your values. See the example file for descriptions of each variable.

| Variable | Description |
|----------|-------------|
| `NGROK_STATIC_DOMAIN` | Your ngrok free static domain (without `https://`) |
| `POSTGRES_USER` | PostgreSQL username for n8n internal DB |
| `POSTGRES_PASSWORD` | PostgreSQL password (local only) |
| `N8N_ENCRYPTION_KEY` | 32-char key for n8n credential encryption |
| `ANTHROPIC_API_KEY` | Claude API key |
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key (admin access) |
| `META_APP_SECRET` | Meta app secret for webhook verification |
| `META_VERIFY_TOKEN` | Webhook verify token (you choose this value) |

**Never commit `.env` to git.** It contains live API keys.

---

## Demo

See [`docs/demo-plan.md`](docs/demo-plan.md) for the full 20-minute demo script targeting hotel/pension owners.

Run pre-demo checks:
```bash
bash scripts/test-checklist.sh
```

One-command startup:
```bash
bash scripts/startup.sh
```

---

## Production Deployment

The demo stack runs on localhost with ngrok. For production:

- Replace ngrok with a VPS (e.g., Hetzner CX22) + Traefik reverse proxy + Let's Encrypt SSL
- Point `WEBHOOK_URL` to your real domain
- Enable n8n basic auth (`N8N_BASIC_AUTH_ACTIVE=true`)
- Use Redis for queue mode (`EXECUTIONS_MODE=queue`)

See [`docs/demo-implementation-plan.md`](docs/demo-implementation-plan.md) for the architecture comparison table.
