# GuestFlow — Business Value Proposition

## The Real Problem for a Small Romanian Pension Owner

They're competing against **Booking.com dependency**. Most small owners get 60-80% of bookings through Booking.com, which takes **15-18% commission per booking**. On a 400 RON/night room, that's 60-70 RON per night — gone. They know it, they hate it, but they don't know how to get out.

The only escape is **direct bookings**: guests who find them on Google, WhatsApp them directly, or see them on Facebook and book without a middleman.

**GuestFlow's three workflows attack exactly that problem.**

---

## How Each Workflow Actually Helps

### 1. WhatsApp Bot — Stop Losing Leads at Night

A pension owner with 8 rooms gets maybe 5-10 WhatsApp inquiries per day in high season. If they miss 2-3 because they were at dinner or sleeping, and those guests booked somewhere else — that's **600-900 RON lost per night**, every night.

The bot's real value: **converting after-hours inquiries that would otherwise bounce to a competitor.**

### 2. Google Review Responder — Better Google Ranking = Free Guests

Google's algorithm ranks businesses **higher** when they respond to reviews consistently. A pension that responds to every review within 24 hours will outrank one that doesn't — even with fewer reviews.

More importantly: a handled negative review damages you far less than an unanswered one. Guests read the response, not just the rating.

The result: **more organic Google traffic → more direct booking attempts → less Booking.com dependency.**

### 3. Social Media Content — The Slow Drip That Builds a Brand

Most small owners post on Facebook once a month, apologetically. Consistent weekly posts with seasonal content (Easter package, summer getaway, Christmas offer) keep them top-of-mind and generate direct messages.

Facebook and Instagram also drive **remarketing** — past guests see a post, remember their stay, share it with a friend who's planning a trip.

---

## The Business Case in Numbers

A typical 8-room Romanian pension in a tourist area:

- Average room: 300 RON/night, average stay 2 nights = **600 RON per booking**
- Booking.com commission: ~100 RON per booking
- If GuestFlow captures **5 extra direct bookings/month** (missed WhatsApp inquiries, Google traffic, social referrals): **500 RON/month saved in commissions + revenue recovered**
- Monthly retainer: €150-200 (~700-950 RON)

**It pays for itself with 5 recovered or redirected bookings. In summer season, that's conservative.**

---

## The Pitch in One Sentence

> "You're already paying Booking.com 15% to bring you guests. We help you keep those guests coming back directly — and capture the ones you're missing at night — for less than the commission on one booking per week."

---

## What GuestFlow is NOT (Be Honest)

It's not a property management system. It doesn't replace their Booking.com account. It doesn't handle payments or reservations. It's a **top-of-funnel + reputation layer** that runs on autopilot — capturing leads, protecting the Google ranking, and keeping social media alive without the owner lifting a finger.

---

## Availability & Integrations

The bot does not check real-time availability. It collects the inquiry and tells the guest the owner will confirm within 2 hours — which mirrors how most small pensions already operate.

**How to frame this to a client:**
> "The bot captures the lead at 2am when you're sleeping. In the morning you have 3 qualified inquiries waiting — names, dates, how many people. You check your calendar, confirm or decline, done. Before, those 3 guests messaged at 2am, got no reply, and booked somewhere else by morning."

### Integration roadmap (Phase 2 upsell)

| Tool | Integration path | Difficulty |
|---|---|---|
| Google Calendar | n8n native node — bot checks blocked dates | Low |
| iCal feed (Booking.com, Airbnb, Lodgify) | n8n polls URL, syncs to Supabase availability table | Low–medium |
| Google Sheets | n8n Sheets node reads a simple available/booked table | Low |
| Smoobu / Cloudbeds / Lodgify | Webhooks or REST API | Medium |
| Booking.com Extranet API | Requires partner certification — not realistic short-term | High |

> "Once you're onboarded, we connect your Booking.com calendar so the bot can check availability in real time. That's phase two, takes about a day to set up."
