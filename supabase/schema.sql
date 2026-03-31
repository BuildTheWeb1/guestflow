-- =============================================================================
-- GuestFlow — Supabase Database Schema
-- =============================================================================
-- Run this in the Supabase SQL Editor for your project.
-- Project: https://supabase.com → SQL Editor → New Query → paste & run.
--
-- Tables:
--   1. clients          — hotel accounts and their WhatsApp / Claude config
--   2. conversations    — one row per guest conversation thread
--   3. messages         — individual messages within conversations
--   4. social_content   — generated social media posts per week
--   5. email_routing    — inbound email classification records
--   6. audit_log        — workflow execution events for debugging
-- =============================================================================

-- Enable UUID generation (already available in Supabase; included for safety)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- =============================================================================
-- 1. clients
-- =============================================================================
CREATE TABLE IF NOT EXISTS clients (
    id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Hotel identity
    hotel_name                TEXT        NOT NULL,
    owner_name                TEXT        NOT NULL,

    -- WhatsApp numbers
    -- owner_wa_number: the hotel owner's personal WhatsApp (receives notifications)
    -- Format: international without '+', e.g. '40722123456'
    owner_wa_number           TEXT        NOT NULL,

    -- whatsapp_phone_number_id: the Meta-assigned phone number ID for the hotel's
    -- WhatsApp Business account. Used as the sender ID in API calls.
    whatsapp_phone_number_id  TEXT        NOT NULL,

    -- wa_access_token: Meta permanent system user token for this client's WA account
    wa_access_token           TEXT        NOT NULL,

    -- Claude system prompt — the full personality/context for this hotel's bot.
    -- Stored here so it can be updated without redeploying workflows.
    system_prompt             TEXT        NOT NULL,

    -- Billing / operational flags
    is_active                 BOOLEAN     NOT NULL DEFAULT true,

    -- client_index: simple integer for ordered display (0 = first client, etc.)
    client_index              INTEGER     NOT NULL DEFAULT 0,

    created_at                TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for the webhook lookup: given a phone_number_id, find the client
CREATE INDEX IF NOT EXISTS idx_clients_phone_number_id
    ON clients (whatsapp_phone_number_id)
    WHERE is_active = true;

COMMENT ON TABLE  clients                         IS 'One row per hotel account. Stores all secrets and configuration needed to run automations for that client.';
COMMENT ON COLUMN clients.whatsapp_phone_number_id IS 'Meta phone number ID (not the phone number itself). Found in Meta Developer → WhatsApp → Getting Started.';
COMMENT ON COLUMN clients.wa_access_token          IS 'Permanent system user token from Meta Business Manager. Rotates annually.';
COMMENT ON COLUMN clients.system_prompt            IS 'Full Claude system prompt for this hotel. Parameterized with room prices, policies, personality.';


-- =============================================================================
-- 2. conversations
-- =============================================================================
CREATE TABLE IF NOT EXISTS conversations (
    id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id         UUID        NOT NULL REFERENCES clients (id) ON DELETE CASCADE,

    -- Guest's WhatsApp number in international format (no +)
    guest_wa_number   TEXT        NOT NULL,

    last_message_at   TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- status: 'active' while guest is engaged, 'closed' after checkout or inactivity
    status            TEXT        NOT NULL DEFAULT 'active'
                                  CHECK (status IN ('active', 'closed')),

    message_count     INTEGER     NOT NULL DEFAULT 0,

    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Fast lookup: for a given client + guest phone, find the active conversation
CREATE INDEX IF NOT EXISTS idx_conversations_client_guest
    ON conversations (client_id, guest_wa_number, status);

CREATE INDEX IF NOT EXISTS idx_conversations_last_message
    ON conversations (last_message_at DESC);

COMMENT ON TABLE  conversations              IS 'One row per guest conversation thread. A guest who contacts the same hotel twice gets two rows (or the same row if re-opened).';
COMMENT ON COLUMN conversations.guest_wa_number IS 'WhatsApp number of the guest (tourist). International format, no +.';


-- =============================================================================
-- 3. messages
-- =============================================================================
CREATE TABLE IF NOT EXISTS messages (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id     UUID        NOT NULL REFERENCES conversations (id) ON DELETE CASCADE,

    -- direction: 'inbound' = guest → bot, 'outbound' = bot → guest
    direction           TEXT        NOT NULL
                                    CHECK (direction IN ('inbound', 'outbound')),

    content             TEXT        NOT NULL,

    -- claude_tokens_used: total tokens (input + output) for this exchange.
    -- Null for inbound messages (no Claude call on inbound).
    claude_tokens_used  INTEGER,

    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Most queries scan by conversation in chronological order
CREATE INDEX IF NOT EXISTS idx_messages_conversation_created
    ON messages (conversation_id, created_at ASC);

COMMENT ON TABLE  messages                   IS 'Individual messages. Each inbound guest message has a paired outbound Claude reply.';
COMMENT ON COLUMN messages.claude_tokens_used IS 'Sum of input_tokens + output_tokens from the Claude API response. Used for cost tracking.';


-- =============================================================================
-- 4. social_content
-- =============================================================================
CREATE TABLE IF NOT EXISTS social_content (
    id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id     UUID        NOT NULL REFERENCES clients (id) ON DELETE CASCADE,

    -- week_of: Monday of the week these posts cover (ISO date string YYYY-MM-DD)
    week_of       DATE        NOT NULL,

    -- posts: JSONB array of generated post objects.
    -- Each element: { id, platform, language, text, hashtags[] }
    posts         JSONB       NOT NULL DEFAULT '[]'::jsonb,

    -- delivered_at: when the batch was sent to the owner via WhatsApp
    delivered_at  TIMESTAMPTZ,

    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Prevent duplicate generations for the same week
    UNIQUE (client_id, week_of)
);

CREATE INDEX IF NOT EXISTS idx_social_content_client_week
    ON social_content (client_id, week_of DESC);

COMMENT ON TABLE  social_content         IS 'Weekly social media post batches generated by Claude and delivered to hotel owners.';
COMMENT ON COLUMN social_content.posts   IS 'JSON array: [{id, platform, language, text, hashtags}]. Stored as-is from Claude output for owner review.';
COMMENT ON COLUMN social_content.week_of IS 'The Monday of the week these posts are intended for. ISO date.';


-- =============================================================================
-- 5. email_routing
-- =============================================================================
CREATE TABLE IF NOT EXISTS email_routing (
    id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id     UUID        NOT NULL REFERENCES clients (id) ON DELETE CASCADE,

    email_subject TEXT        NOT NULL,
    email_from    TEXT        NOT NULL,

    -- priority: assigned by Claude after reading subject + snippet
    priority      TEXT        NOT NULL DEFAULT 'normal'
                              CHECK (priority IN ('urgent', 'normal', 'low')),

    -- forwarded_at: when the classified summary was sent to the owner
    forwarded_at  TIMESTAMPTZ,

    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_email_routing_client_created
    ON email_routing (client_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_email_routing_priority
    ON email_routing (client_id, priority)
    WHERE forwarded_at IS NULL;

COMMENT ON TABLE  email_routing          IS 'Inbound email classification records. Each row represents one email that was triaged by the AI router.';
COMMENT ON COLUMN email_routing.priority IS 'urgent: requires same-day response | normal: respond within 24h | low: FYI only.';


-- =============================================================================
-- 6. audit_log
-- =============================================================================
CREATE TABLE IF NOT EXISTS audit_log (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id       UUID        REFERENCES clients (id) ON DELETE SET NULL,

    -- workflow_name: which n8n workflow fired this event
    workflow_name   TEXT        NOT NULL,

    -- event_type: short slug describing what happened
    -- Examples: 'message_processed', 'review_draft_sent', 'social_batch_delivered',
    --           'error_claude_timeout', 'error_wa_send_failed'
    event_type      TEXT        NOT NULL,

    -- payload: arbitrary JSON context for debugging
    payload         JSONB       NOT NULL DEFAULT '{}'::jsonb,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Most queries: recent events for a client, or all errors
CREATE INDEX IF NOT EXISTS idx_audit_log_client_created
    ON audit_log (client_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_audit_log_event_type
    ON audit_log (event_type, created_at DESC);

COMMENT ON TABLE  audit_log              IS 'Append-only event log for every automation workflow execution. Used for debugging and client reporting.';
COMMENT ON COLUMN audit_log.workflow_name IS 'Snake-case workflow identifier matching the n8n workflow name.';
COMMENT ON COLUMN audit_log.event_type   IS 'Short slug: message_processed | review_draft_sent | social_batch_delivered | error_* etc.';
COMMENT ON COLUMN audit_log.payload      IS 'Arbitrary JSON context: tokens used, review IDs, error messages, etc. Never store raw secrets here.';


-- =============================================================================
-- Row Level Security (RLS)
-- =============================================================================
-- Supabase enables RLS by default on new tables. For the demo, we use the
-- service role key (bypasses RLS entirely), so these policies are not required
-- for the demo to work. They are included here as a production safety baseline.

ALTER TABLE clients          ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations    ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages         ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_content   ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_routing    ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log        ENABLE ROW LEVEL SECURITY;

-- Service role bypasses RLS — this is the only access pattern used in the demo.
-- Add user-level policies here when building an owner-facing dashboard.
