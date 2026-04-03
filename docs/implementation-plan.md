# GuestFlow Demo — Implementation Plan

## Code Fixes (Done by Claude)
- [x] Fix 1: WhatsApp webhook `httpMethod` POST → ALL
- [x] Fix 2: Add 3 missing owner WhatsApp env vars to `.env.example` + scripts
- [x] Fix 3: Log Message node redirected to `audit_log` table with correct schema
- [x] Fix 4: Season calculation rewritten from Jinja2 to JS IIFE
- [x] Fix 5: `META_VERIFY_TOKEN` default cleared, generation instruction added

---

## Your Setup Checklist

### Phase 1 — One-time Accounts

- [x] **1. ngrok** — account created, static domain claimed, auth token configured
- [x] **2. Supabase** — project created, schema + seed SQL run, URL + service key copied

- [ ] **3. Meta Developer** — app GuestFlow exists, complete the steps below _(see guide)_
- [ ] **4. Anthropic** — get Claude API key at console.anthropic.com

---

### Phase 2 — Local Setup

- [ ] **5. Fill `.env`** — copy `.env.example` → `.env`, fill every value
  ```bash
  cp .env.example .env
  # Then generate verify token:
  openssl rand -hex 20
  ```

- [ ] **6. Start the stack**
  ```bash
  # Terminal 1
  bash scripts/startup.sh

  # Terminal 2
  ngrok http --domain=YOUR-NGROK-DOMAIN 5678
  ```

- [ ] **7. Import workflows into n8n**
  - Open http://localhost:5678
  - Add 3 credentials (Claude API, Supabase, Meta WhatsApp — see guide)
  - Import all 3 JSONs from `workflows/`
  - Toggle Workflow 1 (WhatsApp Booking Bot) to **ON**

---

### Phase 3 — Verification

- [ ] **8. Run test checklist**
  ```bash
  bash scripts/test-checklist.sh
  ```
- [ ] **9. Send test WhatsApp message** to Meta test number → Claude should reply in ~5s
- [ ] **10. Execute Workflow 3** (Social Media Generator) → check your WhatsApp for 3 posts

---

## Meta Developer Step-by-Step (for item 3 above)

You already have the GuestFlow app. Follow these steps in order:

### A. Connect WhatsApp to GuestFlow app
1. Go to https://developers.facebook.com/apps → select **GuestFlow**
2. In the left sidebar, click **Use cases** (pencil icon)
3. Find **"Connect with customers through WhatsApp"** → click **Customize**
4. In the **API Setup** panel → connect to an existing or new **WhatsApp Business Account**
5. Note down your **WhatsApp Business Account ID**

### B. Get your Phone Number ID + Temporary Token
1. Still in **API Setup** → scroll to **"Start using the API"**
2. Under step 1, you'll see a **Test phone number** pre-created by Meta
3. Copy the **Phone Number ID** → this is `OWNER_PHONE_NUMBER_ID` in `.env`
4. Under step 2, click **"Generate access token"** → copy it (expires in 24h, you'll replace it in step D)

### C. Add your personal number to the test allowlist
1. Still in API Setup → scroll to **"Add phone numbers"** or **"To"** field under step 2
2. Click **"Add phone number"** → enter your personal WhatsApp number
3. You'll receive a WhatsApp verification code — enter it to confirm

### D. Create a permanent System User token (replaces 24h token)
1. Go to https://business.facebook.com/latest/settings
2. In the left sidebar → **System users** → **Add+**
3. Name it (e.g. "GuestFlow Bot"), role: **Employee**
4. Select the new user → **Assign assets**:
   - Under **Apps** → select GuestFlow → toggle **"Manage app"** (Full control)
   - Under **WhatsApp accounts** → select your account → toggle **"Manage WhatsApp Business Accounts"** (Full control)
5. Click **Assign assets** → then **Generate token**
6. Select your **GuestFlow** app
7. Add these 3 permissions:
   - `business_management`
   - `whatsapp_business_messaging`
   - `whatsapp_business_management`
8. Click **Generate token** → **copy and save it immediately** (shown once)
9. This token goes into both `META_OWNER_ACCESS_TOKEN` and your n8n WhatsApp credential

### E. Configure the Webhook
> ⚠️ ngrok must be running BEFORE you do this step, so Meta can verify the endpoint.

1. In GuestFlow app → left sidebar → **WhatsApp** → **Configuration**
2. Under **Webhook** → click **Edit**
3. **Callback URL**: `https://YOUR-NGROK-DOMAIN/webhook/whatsapp-inbound`
4. **Verify token**: paste the value you generated with `openssl rand -hex 20` (same as `META_VERIFY_TOKEN` in `.env`)
5. Click **Verify and save** — Meta will send a GET to your ngrok URL; if n8n is running it will respond 200
6. After saving, click **Manage** next to Webhook fields → subscribe to **`messages`**

---

## Values to collect during Meta setup

| `.env` variable | Where to find it |
|---|---|
| `META_PHONE_NUMBER_ID` | API Setup → Test phone number section |
| `OWNER_PHONE_NUMBER_ID` | Same as above (for demo, same number) |
| `META_OWNER_ACCESS_TOKEN` | System User → Generate token |
| `META_VERIFY_TOKEN` | You generate: `openssl rand -hex 20` |
| `META_APP_SECRET` | GuestFlow app → App settings → Basic → App secret |
| `META_WABA_ID` | API Setup → WhatsApp Business Account ID |

---

## n8n Credentials (step 7)

| Credential name | Type | Value |
|---|---|---|
| Claude API | HTTP Header Auth | Header: `x-api-key` / Value: Anthropic key |
| Supabase | HTTP Header Auth | Header: `apikey` / Value: Supabase service_role key |
| Meta WhatsApp | HTTP Header Auth | Header: `Authorization` / Value: `Bearer <system_user_token>` |
