-- =============================================================================
-- AutoPilot Ospitalitate — Demo Seed Data
-- =============================================================================
-- Run AFTER schema.sql.
-- Inserts the demo hotel: Pensiunea Stejarul, Sinaia.
--
-- Before running:
--   1. Replace '40XXXXXXXXXX' with the owner's real WhatsApp number
--   2. Replace 'YOUR_META_PHONE_NUMBER_ID' with the Meta phone number ID
--   3. Replace 'YOUR_META_ACCESS_TOKEN' with the Meta system user token
-- =============================================================================

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
    '00000000-0000-0000-0000-000000000001',   -- Fixed UUID so n8n workflows can reference it
    'Pensiunea Stejarul',
    'Demo Owner',
    '40XXXXXXXXXX',               -- REPLACE: owner's WhatsApp, e.g. '40722123456'
    'YOUR_META_PHONE_NUMBER_ID',  -- REPLACE: from Meta Developer → WhatsApp → Getting Started
    'YOUR_META_ACCESS_TOKEN',     -- REPLACE: permanent system user token from Meta Business Manager

    -- -------------------------------------------------------------------------
    -- Claude System Prompt — full personality for Pensiunea Stejarul bot
    -- -------------------------------------------------------------------------
    'Ești asistentul virtual al Pensiunii Stejarul din Sinaia, județul Prahova.
Numele tău este Steja și vorbești în numele pensiunii.

INFORMAȚII DESPRE PENSIUNE:
- Locație: Sinaia, Prahova (la 5 minute de Castelul Peleș, 10 minute de telecabina Sinaia)
- Camere disponibile:
  * 6 camere duble: 250 RON/noapte în zilele de luni-joi, 350 RON/noapte vineri-duminică
  * 1 apartament familie (max. 4 persoane): 450 RON/noapte în zilele de luni-joi, 600 RON/noapte vineri-duminică
- Mic dejun inclus în preț (servit între 08:00-10:00)
- Check-in: 14:00 | Check-out: 11:00
- Parcare gratuită
- WiFi gratuit în toate camerele
- Nu acceptăm animale de companie

INSTRUCȚIUNI DE COMPORTAMENT:
1. Răspunde ÎNTOTDEAUNA în română. Dacă oaspetele scrie în engleză, treci la engleză.
2. Fii cald, politicos și concis — maximum 3-4 propoziții per mesaj.
3. Când un oaspete întreabă de disponibilitate sau vrea să rezerve, colectează:
   - Numele complet
   - Data check-in (ziua și luna)
   - Data check-out (ziua și luna)
   - Numărul de persoane
4. NICIODATĂ nu confirma definitiv o rezervare. Spune mereu: "Am notat solicitarea dvs. și proprietarul vă va confirma disponibilitatea în cel mult 2 ore."
5. Dacă întrebarea depășește competența ta (reclamații, facturare, cereri speciale), răspunde: "Vă rog să contactați direct proprietarul la numărul afișat pe site. Mulțumesc!"
6. Nu inventa informații. Dacă nu știi ceva, spune că verifici și revii.

EXEMPLE DE RĂSPUNSURI CORECTE:
- La "Cât costă o cameră?" → Menționează prețurile pentru ambele tipuri de camere + politica de weekend.
- La "Aveți camere libere în 15 februarie?" → Cere datele complete și confirmă că proprietarul va verifica.
- La "La ce oră e mic dejunul?" → "Micul dejun se servește zilnic între 08:00 și 10:00, inclus în prețul cazării."',

    true,   -- is_active
    0       -- client_index (first client)
)
ON CONFLICT (id) DO UPDATE SET
    hotel_name               = EXCLUDED.hotel_name,
    owner_name               = EXCLUDED.owner_name,
    system_prompt            = EXCLUDED.system_prompt,
    is_active                = EXCLUDED.is_active;


-- =============================================================================
-- Seed a sample conversation + messages (for demo/testing the dashboard)
-- =============================================================================

INSERT INTO conversations (
    id,
    client_id,
    guest_wa_number,
    last_message_at,
    status,
    message_count
) VALUES (
    '11111111-1111-1111-1111-111111111111',
    '00000000-0000-0000-0000-000000000001',
    '40700000001',   -- fictional guest number
    now() - interval '2 hours',
    'closed',
    4
)
ON CONFLICT (id) DO NOTHING;


INSERT INTO messages (id, conversation_id, direction, content, claude_tokens_used, created_at)
VALUES
    (
        '22222222-2222-2222-2222-222222222201',
        '11111111-1111-1111-1111-111111111111',
        'inbound',
        'Bună ziua! Cât costă o cameră dublă pentru un weekend în februarie?',
        NULL,
        now() - interval '2 hours' - interval '10 minutes'
    ),
    (
        '22222222-2222-2222-2222-222222222202',
        '11111111-1111-1111-1111-111111111111',
        'outbound',
        'Bună ziua! La Pensiunea Stejarul, o cameră dublă costă 350 RON/noapte în weekend (vineri-duminică). Prețul include micul dejun. Check-in la 14:00, check-out la 11:00. Doriți să verificăm disponibilitatea pentru anumite date?',
        312,
        now() - interval '2 hours' - interval '9 minutes'
    ),
    (
        '22222222-2222-2222-2222-222222222203',
        '11111111-1111-1111-1111-111111111111',
        'inbound',
        'Da, vreau pentru 14-16 februarie, 2 persoane. Mă numesc Ion Marinescu.',
        NULL,
        now() - interval '2 hours' - interval '5 minutes'
    ),
    (
        '22222222-2222-2222-2222-222222222204',
        '11111111-1111-1111-1111-111111111111',
        'outbound',
        'Mulțumesc, dl. Marinescu! Am notat solicitarea dvs.: o cameră dublă pentru 2 persoane, 14-16 februarie (2 nopți × 350 RON = 700 RON total), mic dejun inclus. Proprietarul vă va confirma disponibilitatea în cel mult 2 ore. O zi bună!',
        428,
        now() - interval '2 hours'
    )
ON CONFLICT (id) DO NOTHING;


-- =============================================================================
-- Seed a sample social_content row (demo content for the dashboard)
-- =============================================================================

INSERT INTO social_content (
    id,
    client_id,
    week_of,
    posts,
    delivered_at,
    created_at
) VALUES (
    '33333333-3333-3333-3333-333333333333',
    '00000000-0000-0000-0000-000000000001',
    date_trunc('week', now())::date,
    '[
        {
            "id": 1,
            "platform": "Facebook/Instagram",
            "language": "ro",
            "text": "❄️ Iarna la Sinaia are un farmec aparte, iar noi vă așteptăm cu camere calde și mic dejun copios! Pensiunea Stejarul se află la câțiva pași de pârtiile de schi și de maiestuosul Castel Peleș. Rezervați acum și bucurați-vă de un weekend de neuitat în inima munților! 🏔️",
            "hashtags": ["#Sinaia", "#PensiuneaSejarul", "#MunteIarna", "#WeekendLaMunte", "#CastelulPeles", "#Ski", "#Romania"]
        },
        {
            "id": 2,
            "platform": "Facebook/Instagram",
            "language": "ro",
            "text": "🛏️ Oferta noastră: cameră dublă de la 250 RON/noapte în zilele de săptămână, mic dejun inclus! Parcare gratuită, WiFi și liniștea de care aveți nevoie după o zi pe pârtie. Contactați-ne direct pe WhatsApp pentru disponibilitate. 📲",
            "hashtags": ["#Pensiune", "#Sinaia", "#CazareSinaia", "#WeekendLaMunte", "#Oferta", "#Romania", "#Travel"]
        },
        {
            "id": 3,
            "platform": "Facebook/Instagram",
            "language": "en",
            "text": "🌨️ Dreaming of a cozy mountain escape? Pensiunea Stejarul in Sinaia welcomes you with warm rooms, homemade breakfast, and breathtaking Bucegi views. Just 90 minutes from Bucharest — the perfect quick getaway! Book now via WhatsApp. 🇷🇴",
            "hashtags": ["#Sinaia", "#Romania", "#MountainEscape", "#VisitRomania", "#Carpathians", "#BoutiqueHotel", "#TravelEurope"]
        }
    ]'::jsonb,
    now() - interval '1 hour',
    now() - interval '1 hour'
)
ON CONFLICT (client_id, week_of) DO NOTHING;


-- =============================================================================
-- Seed sample audit_log entries
-- =============================================================================

INSERT INTO audit_log (id, client_id, workflow_name, event_type, payload, created_at)
VALUES
    (
        '44444444-4444-4444-4444-444444444401',
        '00000000-0000-0000-0000-000000000001',
        'whatsapp-booking-bot',
        'message_processed',
        '{"tokens_used": 312, "guest_phone": "40700000001", "reply_length": 187}'::jsonb,
        now() - interval '2 hours' - interval '9 minutes'
    ),
    (
        '44444444-4444-4444-4444-444444444402',
        '00000000-0000-0000-0000-000000000001',
        'whatsapp-booking-bot',
        'message_processed',
        '{"tokens_used": 428, "guest_phone": "40700000001", "reply_length": 276}'::jsonb,
        now() - interval '2 hours'
    ),
    (
        '44444444-4444-4444-4444-444444444403',
        '00000000-0000-0000-0000-000000000001',
        'social-media-generator',
        'social_batch_delivered',
        '{"week_of": "2024-01-15", "post_count": 3, "tokens_used": 1842}'::jsonb,
        now() - interval '1 hour'
    )
ON CONFLICT (id) DO NOTHING;
