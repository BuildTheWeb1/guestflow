# AutoPilot Ospitalitate — Demo Plan

**Goal:** A working, on-phone demo you can show a hotel/pension owner in a 20-minute conversation. No slides. No mockups. Real messages, real AI responses.

---

## What the Demo Must Show

The demo needs to answer one question in the prospect's mind: *"Does this actually work for my business?"*

Three moments that close:

1. You send a WhatsApp message pretending to be a guest → they see Claude reply in Romanian in seconds
2. You pull up a draft review response that used *their actual Google reviews* → they realize you already did the work
3. You show them a batch of 3 ready-to-post Facebook captions for their hotel → they see tangible output, not a pitch

---

## Demo Environment Setup

### Fake "Demo Hotel" Data

Create one fictional Romanian hotel to use across all demos:

```
Name: Pensiunea Stejarul
Location: Sinaia, Prahova
Rooms: 8 rooms (doubles + a family suite)
Prices: 250 RON/night weekday, 350 RON/night weekend
Breakfast: included
Check-in: 14:00, Check-out: 11:00
Languages: Romanian + basic English
Owner WhatsApp: your own number
```

Load this as a row in Supabase `clients` table — treat it like a real client. The system prompt for Claude should be written for Stejarul specifically (room types, prices, policies). This makes the demo feel real, not generic.

### What You Need Running

- [ ] Hetzner VPS live with n8n accessible at your domain
- [ ] Meta WhatsApp test number registered and webhook verified
- [ ] Your personal WhatsApp number linked as the "owner" notification target
- [ ] Supabase `clients` row for Stejarul with a working `system_prompt`
- [ ] n8n Workflow 1 (WhatsApp Bot) active and tested end-to-end
- [ ] 3 pre-generated review responses (from real Booking.com / Google reviews of similar Sinaia hotels)
- [ ] 3 pre-generated social media posts for Stejarul (spring season, Easter weekend)

---

## Demo Script (20 minutes)

### Minute 0-2: Context, not pitch

Open with a question: *"Câte mesaje primiți pe WhatsApp pe zi de la potențiali clienți?"*

Let them answer. Then: *"Și câte ratați — când ești ocupat, seara, în weekend?"*

This is the pain. You're not selling software — you're selling recovered bookings.

### Minute 2-8: Live WhatsApp Bot Demo

Hand them your phone (or show yours).

Send a WhatsApp message to the demo number as if you're a guest:

> *"Bună ziua! Aveți camere libere în weekendul de Paște? Suntem 2 adulți + un copil de 7 ani."*

Let them watch Claude respond. The reply should arrive in 3-5 seconds in fluent Romanian — confirming availability (or politely explaining it's limited), giving the price, and asking for their check-in date to finalize.

Then send a follow-up:

> *"Cât costă și include micul dejun?"*

Claude responds with exact pricing and breakfast details from the system prompt.

Say: *"Asta se întâmplă la 3 dimineața dacă vrea cineva să rezerve. Dvs. dormiți. Ei primesc răspuns. Mâine dimineață găsiți lead-ul în WhatsApp."*

### Minute 8-13: Google Review Response Demo

Open n8n on your laptop (or show screenshots if you don't want to expose the panel).

Show a real unanswered Google review from a similar pension (found on Google Maps). Then show the Claude-drafted response — personalized, professional Romanian, referencing specific details from the review.

*"Am generat asta în 4 secunde. Dvs. citiți, apăsați Aprobare, și se postează pe Google. Altfel durează 15 minute și de obicei nu se face deloc."*

This is the easiest feature to sell — zero setup friction for the owner, immediately visible on their Google profile.

### Minute 13-18: Social Media Content Demo

Show 3 Facebook/Instagram caption drafts for Stejarul — formatted for Romanian audiences, themed for the current season or upcoming holiday.

Example post:

> *"Paștele la munte — nimic nu se compară 🌿 Rezervați un weekend la Pensiunea Stejarul și bucurați-vă de liniște, aer curat și micul dejun cu produse locale. Locuri limitate pentru 19-21 aprilie! ☎️ [număr] sau WhatsApp direct."*

*"Acestea sunt gata de postat. Le trimitem pe WhatsApp luni dimineața. Copiați, lipiți, publicați — 30 de secunde."*

### Minute 18-20: Close

Don't oversell. Ask: *"Vreți să rulăm asta gratuit 2 luni pentru dvs.? Îmi trebuie 2 ore să configurez totul. Singurul lucru pe care-l cer e un testimonial dacă funcționează."*

If they hesitate on free: *"Sau putem începe direct — 600 EUR setup, 200 EUR/lună. Primul booking recuperat din WhatsApp acoperă o lună de abonament."*

---

## Pre-Demo Prep (Per Prospect)

Before each demo meeting, do 15 minutes of personalization:

1. Find their Google Business profile — screenshot 2-3 of their real unanswered reviews
2. Generate Claude responses to those specific reviews (use the API directly or a quick n8n manual trigger)
3. Note their season/location context — adapt the 3 social posts to their property

This turns a generic demo into *"am pregătit deja câteva lucruri pentru dvs."* — and that's the moment they mentally become a client.

---

## Demo Assets Checklist

| Asset | Status | Notes |
|-------|--------|-------|
| Demo WhatsApp number (Meta test) | Build | Must be real Meta number, not simulator |
| Supabase `clients` row for Stejarul | Build | Fully populated system prompt |
| n8n Workflow 1 (WhatsApp bot) | Build | End-to-end tested |
| 3 sample review responses | Prepare | Use real Sinaia hotel reviews from Google |
| 3 social media post drafts | Prepare | Spring/Easter theme |
| Prospect-specific review responses | Per meeting | 15-min prep per prospect |

---

## What NOT to Demo

- Email routing (Workflow 4) — too abstract, low visual impact. Mention it exists, don't show it.
- n8n interface — confusing to non-technical owners. Keep the backend hidden.
- Pricing or analytics dashboards — not built yet, don't fake it.
- Anything that requires them to do setup during the meeting.

---

## Success Criteria

The demo works if, by minute 15, they ask: *"Și cum funcționează pentru hotelul meu?"* — because that question means they've mentally placed themselves inside the product.

Anything short of that: the pain discovery (minute 0-2) needs to be sharper.
