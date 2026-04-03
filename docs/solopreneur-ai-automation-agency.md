# Solo AI Automation Agency — Romania
## Plan for a Solo Software Engineer with SRL, Claude + VPS Budget

*Compiled March 2026. Built on top of market research in romania-market-research.md.*

---

## Context & Constraints

- **Solo operation** — no employees, no co-founders
- **Budget:** Claude API subscription + VPS (~€20-50/month total infra)
- **SRL already formed** — ready to operate immediately
- **Model:** Productized AI automation agency — not a SaaS product build
- **Revenue target:** First paying client in Month 2, 4,000-6,000 EUR/month by Month 6

---

## Why NOT FiscalAI (Solo)

The romania-implementation-plan.md identifies a real opportunity but has blockers for a solo dev:

- **ANAF SPV API:** Requires production credentials (4-6 week bureaucratic process), notoriously unstable
- **Fiscal domain correctness:** One wrong VAT code sent to ANAF is the client's compliance problem — requires a licensed accountant co-founder
- **Multi-tenant certificate storage:** Complex architecture, high liability
- **Team burn:** Plan assumes 20-30K RON/month team costs before first revenue

FiscalAI is a Year 2 opportunity once you have a client base and revenue. Wrong starting point solo.

---

## Core Model: Productized AI Automation Agency

Build the **same automation package** repeatedly for businesses in one niche. Use Claude as the AI brain + n8n (self-hosted) as the workflow engine. Charge setup fee + monthly retainer. No SaaS product development required. Revenue from week 3-4.

---

## Primary Niche: Romanian Hospitality

**Why:** 20,000+ accommodation units, 50,000+ restaurants, 7.45% CAGR (Mordor Intelligence). Mostly family-run with zero tech infrastructure. Owners are not tech-savvy → they pay for managed services, not DIY tools. Growing market. No regulatory/compliance risk in the automations.

**Secondary niche (Month 3-4):** Romanian real estate agencies — same dynamics, higher contract value.

---

## The Automation Stack

| Tool | Role | Cost |
|------|------|------|
| Hetzner VPS (Germany, EU) | Runs everything, GDPR-compliant | €5-10/month |
| n8n (self-hosted via Docker) | Workflow automation engine | Free |
| Claude API | AI brain for all automations | ~€10-30/month to start |
| Supabase free tier | Simple database per client | Free |
| Cloudflare | Domain + SSL | Free |
| WhatsApp Business API (Meta Cloud) | Client-facing messaging | ~€0.01-0.05/message |

**Total monthly infra cost: €20-50**

---

## The Automation Package

**Product name:** "GuestFlow"

One package. One price. Sold to every pension/hotel in Romania.

### What's Included

**1. WhatsApp Booking Bot**
Claude answers "aveți camere libere în weekend?" inquiries in Romanian 24/7. Checks Google Sheet or simple calendar, gives prices, collects lead info. Most small hotels lose 30-40% of bookings by not replying fast enough on WhatsApp.

**2. Google Review Auto-Response**
n8n polls Google Business reviews nightly. Claude drafts a personalized Romanian response per review. Sends to owner's WhatsApp for 1-click approval, then posts. 30 seconds of owner time vs. 15 minutes manual.

**3. Weekly Social Media Content**
Every Monday, Claude generates 3-5 Facebook/Instagram posts in Romanian based on season, local events, current occupancy. Delivered to owner's WhatsApp as draft text + image prompts. Copy-paste ready.

**4. Email Inquiry Routing**
Emails from Booking.com / their website parsed by Claude. Urgent ones flagged on WhatsApp immediately.

### Pricing

| Fee | Amount |
|-----|--------|
| Setup (one-time) | 500-800 EUR |
| Monthly retainer | 150-250 EUR/month |

Setup covers 4-6 hours of your work per client. Retainer covers Claude API costs + ~1-2h/month maintenance.

### Unit Economics

| Clients | Monthly Recurring Revenue |
|---------|--------------------------|
| 10 clients | ~1,500-2,500 EUR/month |
| 20 clients | ~3,000-5,000 EUR/month |
| Your infra cost | ~€40/month |

---

## Concrete Step-by-Step Plan

### Week 1-2: Build the Demo

1. Set up Hetzner VPS (Ubuntu 22.04, €6/month) — install n8n via Docker
2. Build WhatsApp bot prototype using Meta Cloud API (free up to ~1,000 conversations/month)
3. Connect Claude API to n8n via HTTP node — test with fake hotel data
4. Build Google review poller: n8n → Google My Business API → Claude → WhatsApp approval flow
5. **Goal:** Working demo you can show a hotel owner on your phone by end of Week 2

### Week 3-4: First Client (Free)

6. Find 1 pension/hotel owner via personal network — offer 2 months free for feedback + testimonial
7. Install the stack for them, run it live
8. Document every issue — these become your FAQ and onboarding checklist
9. **Goal:** First real testimonial + screenshots of the system working

### Month 2: First Paying Clients

10. Create a 1-page Romanian website: "Automatizare AI pentru hoteluri și pensiuni din România" — include testimonial and a short demo video
11. Join Facebook groups: "Pensiuni si Hoteluri Romania," "Antreprenori in Turism Romania" — post value content, not ads
12. **Cold outreach tactic:** Go to Booking.com, find pensions with <50 reviews (small, no tech team). Find their Google Business profile. Draft a response to one of their actual unanswered reviews using Claude. Send it to them via WhatsApp: "Am generat automat acest răspuns pentru recenzia dvs. — îl pot face automat pentru toate. Vreți o demonstrație gratuită?"
13. Pricing: 600 EUR setup + 200 EUR/month
14. **Goal:** 3 paying clients by end of Month 2

### Month 3-4: Systematize

15. Build onboarding checklist so each new client setup takes <4 hours
16. Create reusable n8n workflow templates (Notion or local docs)
17. Collect testimonials and case study screenshots
18. Add one more automation to the package: **occupancy-based dynamic pricing suggestions** (Claude analyzes Booking.com calendar, suggests when to raise/lower prices)

### Month 4-6: Second Niche — Real Estate

Romanian real estate agencies (imobiliare.ro has thousands):

**Package:**
- Auto-generate property listing descriptions in Romanian from photos + basic facts
- WhatsApp lead qualification bot (collects budget, location, timeline before agent time spent)
- Automated follow-up sequences for cold leads

**Pricing:** 800-1,200 EUR setup + 300-400 EUR/month (larger businesses, higher value)

---

## 6-Month Revenue Projection

| Month | Clients | MRR |
|-------|---------|-----|
| 1 | 1 (free) | 0 EUR |
| 2 | 3 | ~600 EUR |
| 3 | 7 | ~1,400 EUR |
| 4 | 12 | ~2,400 EUR |
| 5 | 16 | ~3,200 EUR |
| 6 | 20-25 | ~4,000-6,000 EUR |

At 20 hospitality + 5 real estate clients: ~5,000-6,000 EUR/month with ~10h/week maintenance. Remaining time goes to sales and new automations.

---

## The Single Most Important First Action

**This week:** Build the WhatsApp → Claude → Google Review response flow for a real hotel. Once you have a working demo on your phone, closing the first paying client is a 20-minute conversation.

The cold outreach tactic (personalized demo using their own Google reviews) is the fastest path to a first paying client — far more effective than any landing page or ad.

---

## Year 2 Expansion Options

With 20+ clients and stable revenue, revisit:

1. **FiscalAI-lite** — offer e-Factura automation to your existing SME network (without building the full ANAF integration from scratch — use an accounting firm as the domain expert partner)
2. **Agriculture** — EU CAP subsidy documentation automation for agri-food processors (~15,000 companies)
3. **Construction** — permit tracking and subcontractor compliance for the 50,000 small contractors in Romania's 9.2% growth construction sector

---

*See also: romania-market-research.md (full market data), romania-implementation-plan.md (FiscalAI SaaS plan), romania-costs-and-difficulty.md (cost breakdown for FiscalAI)*
