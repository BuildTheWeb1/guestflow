# GuestFlow — Pricing & Cost Breakdown

## Fixed Infrastructure (shared across all clients)

| Item | Cost |
|------|------|
| Hetzner VPS (or similar) | €6-10/month |
| Supabase free tier | €0 |
| n8n self-hosted | €0 |
| Cloudflare | €0 |
| **Total fixed** | **~€10/month** |

This cost doesn't grow until you have many clients.

---

## Variable Costs Per Client/Month

### Claude API (claude-opus-4-5)

| Workflow | Volume | Tokens/run | Monthly tokens |
|----------|--------|-----------|----------------|
| WhatsApp bot | 40 inquiries | ~1,500/exchange | ~60,000 |
| Review responder | 8 reviews | ~600 | ~5,000 |
| Social media | 4 weeks | ~1,000 | ~4,000 |
| **Total** | | | **~70,000 tokens** |

At current Opus pricing (~$15 input / $75 output per MTok, blended ~$45/MTok):
**~€3-5/month per client**

### Meta WhatsApp (user-initiated, Europe)
~€0.06 per 24h conversation window. At 40 inquiries/month:
**~€2-3/month per client**

### Total variable cost per client: **~€5-8/month**

---

## Setup Time Per Client (current, manual)

| Task | Time |
|------|------|
| Write/adapt system_prompt in Supabase | ~1h |
| Meta WhatsApp credentials + webhook registration | ~1h |
| Seed clients row, test all 3 workflows | ~1h |
| Onboarding call + handoff | ~1h |
| **Total** | **~4 hours/client** |

> Note: The biggest friction is getting the client's Meta WhatsApp Business phone number configured. Budget an extra hour for non-technical clients.

---

## Pricing

| Fee | Amount | Rationale |
|-----|--------|-----------|
| Setup (one-time) | **€400-600** | Covers ~4h setup + back-and-forth buffer |
| Monthly retainer | **€150-200/month** | €10 infra share + €8 variable + €130 margin |

### Unit Economics

| Clients | Monthly costs | MRR (at €175/mo avg) | Net margin |
|---------|--------------|----------------------|------------|
| 5 | ~€50 | ~€875 | ~€825 |
| 10 | ~€90 | ~€1,750 | ~€1,660 |
| 20 | ~€170 | ~€3,500 | ~€3,330 |

---

## Notes

- Setup fee should not be discounted — it signals quality and covers real time
- First client can be offered free setup (2 months free) in exchange for testimonial
- Retainer covers Claude API + WhatsApp costs + ~2h/month maintenance at scale
- Token costs will decrease significantly when switching from Opus to Sonnet/Haiku for simpler tasks (future optimization)
