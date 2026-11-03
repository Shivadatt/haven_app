-- ============================================================================
-- HAVEN PARENTAL CONTROL -- STAGE 2 -- A3d: FIREBASE IDENTITY MAPPING (M-B)
-- File: docs/stage2/migrations/A3d-firebase-identity-mapping.sql
-- ============================================================================
-- TARGET PROJECT (the ONLY permitted target): parent-control-staging
--                                            ref dzonzgngwxclhfnvxtvu
-- FORBIDDEN TARGET: parent-control-prod / hhqgreaoqulmfwfwarhc. That ref appears in
--   cited files as provenance only. Nothing here addresses it as a target; the
--   sentinel guard in SECTION 0 aborts a wrong-project paste before DDL #1, exactly
--   as in A3-staging-load-v1.sql SECTION 0. ev: docs/stage2/S2-EXEC-08-identity-
--   decision-A13-final.md:9 (same target declaration); 00-stage2-execution-plan.md:149-153 (D-09/J-03).
--
-- WHAT THIS FILE IS
--   The SQL realisation of mapping store M-B, the single missing dependency for the
--   owner's Phase 4 (Firebase authentication bridge). The owner instruction driving
--   this file is, verbatim from S2-EXEC-08: "M-B mapping table must exist."
--   The ENTIRE prior specification of M-B is one sequence-diagram line:
--     S2-A1-auth-architecture.md:503  "Mapping store M-B
--                                      (provider, firebase_uid) UNIQUE -> supabase_user_id"
--   ratified in approval-package-v3-implementation-instruments.md:46 and restated at
--   S2-EXEC-08-identity-decision-A13-final.md:46 (consequence 6) and :84 (the Third-Party
--   Auth mapping row). Everything beyond that line in this file is NEW DESIGN and is
--   labelled EVIDENCED (file:line), DERIVED (from what), or DESIGN - REQUIRES OWNER
--   APPROVAL (choice + rejected alternative). Nothing here was recovered from any
--   database; M-B exists in no SQL form today (S2-EXEC-08:46 "M-B exists today in no SQL form").
--
-- STATUS: *** NOT EXECUTED *** -- no statement in this file has been run, and none was
--   run to produce it. Assembled offline from local files only: no dashboard, no browser,
--   no SQL execution, no REST, no supabase CLI, no database connection, no curl.
--
-- APPROVALS REQUIRED BEFORE ANY PASTE (all three, in this order):
--   A2'(a) -- the environment sentinel private.s2_environment must ALREADY EXIST
--              (created before the A3 load; ev: 00-stage2-execution-plan.md:92,:135,:149-153,
--              restated in A3-staging-load-v1.sql:18-23). A2'(a) is UNSIGNED.
--   A3     -- authorises the G3-c staging schema load that creates public.profiles, the
--              FK target of this table. A3-staging-load-v1.sql:23 records A3 as UNSIGNED.
--              THIS FILE CANNOT LOAD BEFORE THE A3 LOAD: the FK
--              firebase_identity_mapping_supabase_user_id_fkey -> public.profiles(id)
--              fails 42P01 if profiles does not exist, and the SECTION 0 sentinel aborts
--              before that anyway. Dependency order is explicit:
--                A2'(a) executed  ->  A3 load committed  ->  THIS FILE  ->  (A13 browser steps)
--   A13    -- S2-EXEC-08-identity-decision-A13-final.md SECTION 4. Authorises "The one
--              unique server-controlled mapping Firebase UID -> Supabase profile, realised
--              ONLY through mapping store M-B" (clause 4, :113-115). Fence status:
--              DECIDED - INSTRUMENT PREPARED, FENCE UNSIGNED (S2-EXEC-08:28,:134-137);
--              it is NOT `APPROVED` and this file must not be pasted while unsigned.
--   If this file is pasted after A2'(a)+A3 but BEFORE the A13 fence is signed, it loads a
--   table nothing is authorised to write -- permitted by clause 4? No: clause 4 is the
--   authorisation. Sign A13 first. (S2-EXEC-08:28 "nothing in §5 may run until it is")
--
-- PRODUCTION IS OFF-LIMITS / NO SECRETS / NO PII
--   Production was never contacted by this authoring pass. No key, token, JWT, account
--   address, email or user row appears anywhere below. The table is created EMPTY; with
--   zero approved fixtures (A14 unsigned, S2-EXEC-08:165 point 3) it must remain empty
--   after load -- verification query V-9 proves that, it is not a placeholder.
--
-- LABEL KEY (used on every element below)
--   EVIDENCED  = read from a cited repo file (the citation IS the evidence)
--   DERIVED    = reasoned from cited evidence; the derivation is stated
--   DESIGN     = a choice with no repo evidence; requires owner approval before paste;
--                the rejected alternative is recorded inline (house rule of
--                A3b-functions-triggers-candidate.sql:27-37: nothing invented is
--                presented as recovered, no always-true objects, no stubs).
-- ============================================================================


-- ============================================================================
-- SECTION 0 -- TRANSACTION + WRONG-PROJECT SENTINEL GUARD  (1 active statement)
-- ============================================================================
-- One BEGIN/COMMIT wrapper (house style: A3-staging-load-v1.sql:77-98 transaction
-- policy; A3c-notification-backend.sql:107-113). A failure anywhere below rolls the
-- whole addendum back, leaving no half-created mapping table.
-- The guard is the same sentinel, tested the same way, as A3-staging-load-v1.sql:108-118
-- and A3c-notification-backend.sql:115-120: absent sentinel or non-'staging' value =
-- abort, never "run anyway". It is also what makes a production paste impossible by
-- construction, because private.s2_environment exists only in staging.
BEGIN;                                   -- transaction control; not counted as a statement

DO $$                                                    -- ev: A3-staging-load-v1.sql:108-118 (same guard shape);
DECLARE v_env text;                                      --     docs/stage2/patches/S2-P01-e2-f8.sql:105-111
BEGIN
  IF to_regclass('private.s2_environment') IS NULL THEN
    RAISE EXCEPTION 'A3d mapping load: sentinel private.s2_environment is missing; A2''(a) is not executed -- refusing to run outside staging';
  END IF;
  EXECUTE 'SELECT environment FROM private.s2_environment LIMIT 1' INTO v_env;
  IF v_env IS DISTINCT FROM 'staging' THEN
    RAISE EXCEPTION 'A3d mapping load: sentinel reads %, not staging -- refusing', COALESCE(v_env, '<null>');
  END IF;
END $$;

-- ============================================================================
-- SECTION 1 -- SCHEMA PLACEMENT (0 statements; a decision, recorded)
-- ============================================================================
-- PLACEMENT: public. EVIDENCED rationale, adopted from the identical ruling in
-- A3c-notification-backend.sql:195-205 ("Putting rows in `private` would invent a
-- placement the capture does not show, would sit outside every RLS posture decision
-- ... and would make the A3 staging/production equivalence diff uninterpretable").
-- The mapping row IS an application record (it is the authorization pivot of the
-- bridge, S2-EXEC-08 §3 mapping row :84), so it belongs with the other 19+1 tables.
-- DEFECT M-4 RELATIONSHIP (asked explicitly, so answered explicitly): M-4 is the
-- finding that the reconstructed source artefact emitted no GRANT USAGE ON SCHEMA
-- private statement (S2-EXEC-04 M-4, measured at A3-staging-load-v1.sql:863-865).
-- That defect is repaired independently in the A3 load as deviation D-5
-- (A3-staging-load-v1.sql:876: GRANT USAGE ON SCHEMA private TO authenticated, from
-- evidence g1-b3b-20261029.json schema_usage). THIS FILE NEITHER DEPENDS ON NOR TOUCHES
-- private USAGE: the object lives in public, and the table deliberately grants the
-- clients NOTHING (SECTION 6), so the M-4 question ("does authenticated see it?") is
-- moot for this object by design, not by accident. If the owner instead directed this
-- table into private, M-4/D-5 would become load-order-relevant AND the zero-grant
-- posture below would need re-deriving; rejected as DESIGN D1 (SECTION 12 register).
-- No CREATE SCHEMA is emitted (public and private both already exist post-A3;
-- A3-staging-load-v1.sql:123-126).

-- ============================================================================
-- SECTION 2 -- TABLE AND COLUMNS  (1 active statement, 9 columns)
-- ============================================================================
-- The shape follows the ratified M-B sketch, S2-A1-auth-architecture.md:155
-- ("a separate mapping table ... (external provider, external uid, supabase user id,
-- created/confirmed timestamps) with a unique constraint on (provider, external uid)
-- and ON DELETE CASCADE ... RLS enabled with zero policies is deny-all, which is the
-- safe default here") and the ratified single line at :503. Column order follows the
-- house convention: surrogate id first (uuid + gen_random_uuid() is the capture's
-- universal pattern for tables with client-visible lifecycle rows -- A3c:216-220 citing
-- g1-q8 ordinal 1; devices :222, audit_logs :145, all PKs in A3 SECTION 20 :401-419).

CREATE TABLE public.firebase_identity_mapping (

  -- 2.1 Surrogate PK. DERIVED: same shape as the 19 captured tables
  -- (A3-staging-load-v1.sql:222,:145; g1-q8 via :137-140). DESIGN note: could have been
  -- a natural composite PK (provider, firebase_uid); rejected -- every table in the
  -- capture carries a surrogate id except the two junction-shaped ones
  -- (safe_zone_states, child_contact_ids), and audit rows want a single-id reference.

  id                        uuid          NOT NULL DEFAULT gen_random_uuid(),

  -- 2.2 Provider discriminator. EVIDENCED that the pair (provider, external uid) is the
  --     KEY of M-B: S2-A1-auth-architecture.md:503, :165 ("A unique index on
  --     (provider, external_uid) ... the programme's composite-uniqueness idiom"), and
  --     A3c-notification-backend.sql:222-230 established the same discriminator idiom
  --     for push_tokens (`provider text not null default 'fcm'` + single-value CHECK,
  --     "Adding apns is a CHECK edit, not a migration"). WHY provider is IN the key
  --     (owner brief requirement): the ratified A13 sentence is "the ONE unique
  --     server-controlled mapping Firebase UID -> Supabase profile" (S2-EXEC-08:113-114)
  --     -- uniqueness is per (issuer, subject) pair, not "one row per user". A UID is
  --     only meaningful inside the issuer that minted it; the day a second external
  --     issuer is ever ratified, dropping provider from the key would require ALTERing
  --     the constraint (a rewrite), keeping it makes that future a CHECK edit
  --     (pure-additive posture, S2-A1:155 "extensible to more providers", C4 rule :214-215).
  provider                  text          NOT NULL DEFAULT 'firebase'::text,

  -- 2.3 The external subject: the Firebase UID, i.e. the `sub` claim of the verified ID
  --     token (S2-EXEC-08:83 "Subject claim -> user identity | `sub` (the Firebase UID)").
  --     text, not uuid: a Firebase UID is NOT a UUID -- EVIDENCED at
  --     S2-A1-auth-architecture.md:183-184 (fact F-1: "A Firebase UID is not a UUID");
  --     the opaque-string-in-text precedent is devices.installation_id
  --     (A3-staging-load-v1.sql:225, g1-q8 ordinal 4, echoed A3c:232-234).
  --     Length/charset: DESIGN -- REQUIRES OWNER APPROVAL (register item D3).
  --     The repository holds NO captured Firebase UID sample (E-4 is `[N]`,
  --     S2-A1-auth-architecture.md:533: "Firebase ID-token lifetime, iss, aud ... general
  --     platform knowledge, unverified here"). Chosen: 1..128 chars, alphanumeric,
  --     bound borrowed from the repo's existing 128-char precedents
  --     (devices_installation_id_check `>= 8 AND <= 128`, A3:461; audit_logs_target_id_check
  --     `<= 128`, A3:435) and the regex idiom from child_contact_ids_contact_id_check
  --     (A3:437) / device_pairing_tokens_code_hash_check (A3:448). The owner brief states
  --     the UID is "128-char-capable alphanumeric" -- consistent with the bound chosen.
  --     Rejected: `~ '^[A-Za-z0-9]{128}$'` (exactly-128) -- no repo evidence any UID has
  --     ever been observed, and a wrong length assumption on a CHECK silently rejects the
  --     first real binding at runtime (fail-closed, but an outage); 1..128 cannot fail closed.
  firebase_uid              text          NOT NULL,

  -- 2.4 The Supabase side: the application profile this external identity resolves to.
  --     Column name kept from the spec line (`supabase_user_id`, S2-A1:503, S2-EXEC-08:84).
  --     uuid NOT NULL, FK to public.profiles(id) (SECTION 3). DESIGN -- REQUIRES OWNER
  --     APPROVAL (register item D2) on the FK TARGET: S2-A1:155 sketched the CASCADE FK
  --     on auth.users(id); this file targets public.profiles(id) instead because the
  --     owner's ratified sentence is "the Firebase UID resolves to a Supabase PROFILE only
  --     through M-B" and every evidenced function keys ownership off the profile row
  --     (S2-EXEC-08:42 §2(4) lists device-command :67, device-register :82, auth-bootstrap
  --     :53-54; A3c:242-248 made profiles.id "the ownership key"). Targeting profiles
  --     makes referential integrity do real work: a mapping row cannot exist that points
  --     at an auth user with no profile -- the exact drift the §2(4) provisioning gap
  --     would otherwise leave undetected until a 403 profile_missing
  --     (14-edge-function-security-audit.md:80-81). Rejected alternative: FK to
  --     auth.users(id) per the :155 sketch -- weaker (permits profile-less targets), and
  --     it is the only other object in this schema allowed to touch auth
  --     (profiles_id_fkey is "the artefact's ONE genuine cross-schema FK", A3:527-531;
  --     adding a second cross-auth FK is a larger deviation than reusing profiles).
  --     NOTE profiles.id = auth.users.id by construction (A3:301-307 + profiles_pkey A3:413
  --     + profiles_id_fkey A3:527, ON DELETE CASCADE), so resolving through profiles also
  --     deletes the mapping row when the identity is deleted -- same CASCADE semantics
  --     the :155 sketch asked for.
  supabase_user_id          uuid          NOT NULL,

  -- 2.5 Lifecycle status. Domain {'active','revoked'}: DESIGN -- REQUIRES OWNER APPROVAL
  --     (register item D4). EVIDENCED domain style: status columns are CHECK'd text with
  --     ANY(ARRAY[...]) everywhere -- devices_status_check ('pending','active','revoked'),
  --     A3:466; device_pairing_tokens_status_check, A3:451. The third device value
  --     'pending' is deliberately NOT copied: a mapping row is only ever written AFTER
  --     a server-side token verification succeeds (A13 clause 5, S2-EXEC-08:117-118), so
  --     a not-yet-usable state has no evidenced producer. Rejected: 3-value domain with
  --     'pending' -- invents a state no approved flow creates (A3b honesty rule :32-34,
  --     "a missing body is never stubbed"; same logic forbids a status with no writer).
  status                    text          NOT NULL DEFAULT 'active'::text,

  -- 2.6 Revocation timestamp. THE NAME IS THE EVIDENCE: devices has exactly this column
  --     (credential_revoked_at timestamptz, A3-staging-load-v1.sql:233, g1-q8 ordinal ~20;
  --     UPDATE grant at g1-q6) and `requireDevice` refuses access when it is non-null
  --     alongside status != 'active' (14-edge-function-security-audit.md:153-157;
  --     S2-EXEC-FINAL.md:417 S-2: "the device channel is the only one of the three with an
  --     evidenced per-credential revocation primitive"). Reusing the column NAME and the
  --     refusal PREDICATE is what keeps the two revocation models from diverging
  --     (owner brief requirement 4; A13 :130-131 "Revocation ... designed at the mapping
  --     row, not only at the token"). NULL = never revoked.
  credential_revoked_at     timestamp with time zone,

  -- 2.7/2.8 Audit timestamps. EVIDENCED house pattern: created_at/updated_at timestamptz
  --     NOT NULL DEFAULT now() on lifecycle tables (devices :245-246, families :255-256).
  --     updated_at maintenance: NO trigger is emitted (A3c O-3, A3c:1117-1120 -- whether
  --     updated_at is trigger-maintained is unverified and the emitted artefact contains
  --     0 triggers; this file copies the column shape, not an invented trigger).
  created_at                timestamp with time zone NOT NULL DEFAULT now(),
  updated_at                timestamp with time zone NOT NULL DEFAULT now(),

  -- 2.9 THE FAIL-CLOSED RESOLUTION COLUMN. DESIGN -- REQUIRES OWNER APPROVAL
  --     (register item D6): a PG12+ stored GENERATED column, the first in this programme
  --     (no generated column exists among the 183 captured columns -- g1-q8 via A3:137).
  --     Purpose (owner brief requirement 2): make revocation the DEFAULT of the lookup,
  --     not a flag callers must remember to consult. The value of this column IS the
  --     authorization answer: it resolves the pair to the profile ONLY while BOTH
  --     revocation signals are clear, using exactly requireDevice's refusal predicate
  --     (status must be 'active' AND credential_revoked_at must be NULL --
  --     14:153-157). A revoked row therefore CANNOT resolve to any profile through the
  --     documented read path (SECTION 7), even with a valid, unexpired Firebase token --
  --     A13 :131 verbatim: "A revoked mapping row must fail closed even with a valid,
  --     unexpired Firebase token." Token validity is Supabase/Firebase's layer; this
  --     column is the mapping row's layer, and the two are independent by construction.
  --     Rejected alternatives: (a) plain two-column layout + "remember the WHERE clause"
  --     discipline -- the divergence-and-forget failure mode the brief names; (b) an
  --     `enabled boolean` flag -- a flag is exactly what must not need consulting;
  --     (c) a SECURITY DEFINER lookup function -- invents a return type the programme
  --     forbids inventing outside the A3b ruling (A3b:28-31 standing prohibition 1), and
  --     hides the lookup from PostgREST with zero evidence it is exposed at all
  --     (0 of 38 functions exposed, S2-A1:489). The generated column keeps the contract
  --     a plain column read. LIMITATION L-2 (SECTION 5): a caller with service_role can
  --     still SELECT supabase_user_id directly and bypass this; SQL cannot police the
  --     one role that bypasses everything. Recorded, not solved.
  active_supabase_user_id   uuid GENERATED ALWAYS AS (
                              CASE WHEN (status = 'active'::text)
                                        AND (credential_revoked_at IS NULL)
                                   THEN supabase_user_id
                              END
                            ) STORED
);

-- ============================================================================
-- SECTION 3 -- CONSTRAINTS  (9 active statements: 1 PK, 2 UNIQUE, 5 CHECK, 1 FK)
-- ============================================================================
-- Care modelled on A3 SECTION 20 (137 constraints, ordering PK -> UNIQUE -> CHECK -> FK,
-- A3:392; all validated, no NOT VALID emitted -- A3:390-391). Every target column of the
-- FK exists in A3-staging-load-v1.sql as actually written: profiles.id is declared at
-- A3:302 with profiles_pkey at A3:413. No reference is made to any column the A3 load
-- does not create.

-- ---- PRIMARY KEY ----
ALTER TABLE public.firebase_identity_mapping ADD CONSTRAINT firebase_identity_mapping_pkey PRIMARY KEY (id);
  -- DERIVED: every one of the 19 captured tables has a *_pkey (A3:401-419).

-- ---- UNIQUE (the core of the ratified line) ----
-- (provider, firebase_uid) UNIQUE: EVIDENCED -- this IS the S2-A1:503 spec line,
-- ratified twice (approval-package-v3:46; S2-EXEC-08:46,:84,:113-114). It makes the
-- mapping "one unique, server-controlled" mapping: no issuer can claim the same UID
-- resolves to two profiles; a re-verification of the same verified sub is an upsert
-- against this key (S2-A1:168-170 idempotency requirement -- idempotency lives at the
-- Edge Function's merge, which this constraint makes conflict-detectable).
ALTER TABLE public.firebase_identity_mapping ADD CONSTRAINT firebase_identity_mapping_provider_firebase_uid_key UNIQUE (provider, firebase_uid);
  -- Composite-unique precedent in-capture: devices_family_installation_key (A3:427),
  -- family_members_family_user_key (A3:428), usage_daily triple (A3:430).
ALTER TABLE public.firebase_identity_mapping ADD CONSTRAINT firebase_identity_mapping_provider_supabase_user_id_key UNIQUE (provider, supabase_user_id);
  -- DESIGN -- REQUIRES OWNER APPROVAL (register item D7): the reverse 1:1. The ratified
  -- text says "the Firebase UID maps to ONE Supabase profile" (S2-EXEC-08:20) and A13
  -- clause 4 says "one unique server-controlled mapping" (:113-114); it does NOT say a
  -- profile may hold several UIDs from the same issuer. This constraint forbids alias
  -- pile-up (one profile claimed by N external identities -- the confusion attack A13
  -- clause 5's "never establishes parent-child ownership" :118-119 guards against at the
  -- token layer; this guards it at the row layer). Rejected alternative: many-to-one
  -- allowed (strict reading of "one unique mapping" as key-side only) -- cheaper for a
  -- hypothetical future multi-account merge, but merge is not evidenced anywhere and
  -- S2-A1:171-174 shows even email-merge posture is UNVERIFIED (enable_manual_linking is
  -- a local-only file value). If the owner prefers the strict reading, DROP this one
  -- constraint; nothing else in the file depends on it.

-- ---- CHECK (5 statements) ----
ALTER TABLE public.firebase_identity_mapping ADD CONSTRAINT firebase_identity_mapping_provider_check CHECK ((provider = ANY (ARRAY['firebase'::text])));
  -- DERIVED: A3c:222-230 identical ruling for push_tokens.provider ("The CHECK lists
  -- exactly one value because exactly one provider is evidenced"). Adding a second
  -- issuer = CHECK edit, and the KEY already accommodates it (SECTION 2.2 rationale).
ALTER TABLE public.firebase_identity_mapping ADD CONSTRAINT firebase_identity_mapping_firebase_uid_length_check CHECK (((char_length(firebase_uid) >= 1) AND (char_length(firebase_uid) <= 128)));
  -- DESIGN (register D3): bound borrowed from devices_installation_id_check 8..128
  -- (A3:461) and audit_logs_target_id_check <=128 (A3:435); lower bound 1 not 8 because
  -- no repo evidence fixes a minimum (rejected: copy `>= 8` from installation_id -- that
  -- 8 is installation-specific folklore, not a Firebase fact).
ALTER TABLE public.firebase_identity_mapping ADD CONSTRAINT firebase_identity_mapping_firebase_uid_pattern_check CHECK ((firebase_uid ~ '^[A-Za-z0-9]+$'::text));
  -- DESIGN (register D3): alphanumeric per the owner brief; charset claim NOT verified
  -- by any repo sample (E-4 `[N]`, S2-A1:533). Regex CHECK idiom EVIDENCED at A3:437,:448,:465.
  -- If Google ever issues a non-alphanumeric sub this CHECK rejects the BINDING only
  -- (fail-closed at write); it cannot strand an existing row because writes are
  -- server-controlled.
ALTER TABLE public.firebase_identity_mapping ADD CONSTRAINT firebase_identity_mapping_status_check CHECK ((status = ANY (ARRAY['active'::text, 'revoked'::text])));
  -- DERIVED domain style: A3:466 (devices), A3:451 (pairing tokens). Values DESIGN (D4).
ALTER TABLE public.firebase_identity_mapping ADD CONSTRAINT firebase_identity_mapping_revoked_consistency_check CHECK (((status = 'revoked'::text) = (credential_revoked_at IS NOT NULL)));
  -- Biconditional: revoked <=> timestamp present. Precedent EVIDENCED:
  -- family_members_removed_consistency `((status = 'removed') = (removed_at IS NOT NULL))`
  -- A3:469. DESIGN -- REQUIRES OWNER APPROVAL (register item D5): rejected alternative
  -- was the devices-style one-way check (devices_revoked_credential_consistency A3:464 is
  -- one-way because devices must tolerate `revoked`+`secret_hash IS NULL` separately).
  -- Chosen stronger form here: a mapping row with status='revoked' and no timestamp, or
  -- a timestamp without status, is exactly the two-revocation-models-diverge failure the
  -- owner brief forbids (requirement 4); the biconditional deletes that state space.
  -- The ACCESS predicate (2.9) still reads both signals independently, matching
  -- requireDevice's refusal form, so parity holds either direction.

-- ---- FOREIGN KEY ----
ALTER TABLE public.firebase_identity_mapping ADD CONSTRAINT firebase_identity_mapping_supabase_user_id_fkey FOREIGN KEY (supabase_user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
  -- EVIDENCED pattern: the 44 captured FKs are all `REFERENCES public.profiles(id)` with
  -- CASCADE/SET NULL (A3:500-547); CASCADE for ownership-pivoting FKs is the norm
  -- (devices_child_user_id_fkey CASCADE A3:515; families_owner_id_fkey A3:517). ON DELETE
  -- CASCADE here means: when a profile goes (and profiles.id CASCADEs from auth.users per
  -- A3:527), its external binding dies with it -- no orphan can re-authorize a deleted
  -- human. Schema-qualified to public. per the A3 D-1/M-5 repair (A3:393-396).
  -- THIS IS THE LOAD-ORDER LOCK: profiles exists only after the A3 load. Section header
  -- states the dependency; query V-2 proves the binding.

-- ============================================================================
-- SECTION 4 -- INDEXES  (1 active statement)
-- ============================================================================
-- The two UNIQUE constraints create their backing indexes implicitly -- no re-emit, same
-- suppression logic as A3 SECTION 30 (A3:552-557: "28 SUPPRESSED (constraint-backed)").
-- The (provider, firebase_uid) constraint index IS the read-path index: the canonical
-- lookup (SECTION 7) is an equality on exactly that pair.
CREATE INDEX firebase_identity_mapping_supabase_user_id_idx ON public.firebase_identity_mapping USING btree (supabase_user_id);
  -- DERIVED: every captured FK column without a constraint-backed index got a plain
  -- btree index -- devices_child_user_id_idx (A3:570), family_members_user_id_idx
  -- (A3:577). Needed for the reverse check ("what external identities does this profile
  -- carry?") at revocation time and for CASCADE integrity probing without seq scans.

-- ============================================================================
-- SECTION 5 -- RLS POSTURE  (1 active statement)  + THE LIMITATION, IN PLAIN TEXT
-- ============================================================================
ALTER TABLE public.firebase_identity_mapping ENABLE ROW LEVEL SECURITY;
  -- EVIDENCED posture: all 19 captured tables are rls_enabled=true, rls_forced=false,
  -- owner postgres (g1-q1-20261029.json, all 19 rows). S2-A1:155 chose this posture for
  -- M-B explicitly: "RLS enabled, no exposure (A-13/A-14) ... RLS enabled with zero
  -- policies is deny-all, which is the safe default here." Zero policies are emitted
  -- (none is evidenced for a table that does not exist in the capture; inventing one
  -- repeats the defect A3b:27-37 refuses to commit for the 9 gating functions).
  -- rls_forced is NOT set (all 19 captured tables false, g1-q1; FORCE would diverge and
  -- changes nothing for the only role that can reach this table anyway -- see below).

-- SERVER-WRITE-ONLY: WHAT ACTUALLY ENFORCES IT (owner brief requirement 3, answered
-- with the strongest mechanism the evidence supports, which is PRIVILEGES not RLS):
--   (a) PRIVILEGES (SECTION 6): zero grants to anon/authenticated. No client role can
--       SELECT, INSERT, UPDATE or DELETE this table at all. EVIDENCED precedent: five of
--       the nineteen captured tables already hold NO authenticated row in g1-q6.table_grants
--       -- devices, device_pairing_tokens, child_contact_ids, pairing_attempts,
--       safe_zone_states (the five secret/credential-bearing tables; g1-q6 rows for those
--       names are service_role-only; g1-q1.table_acl shows no `authenticated=` for them).
--       This table joins that group deliberately: it is a credential-mapping table.
--   (b) NO CLIENT PATH EXISTS ANYWAY: PostgREST exposes 0 of 19 tables (S2-A1:489, A-14),
--       so the dashboard-API surface never reaches public tables for anon/authenticated;
--       and all 9 Edge Functions run with the service-role key (E2, S2-A1:476-477).
--   (c) THE HONEST LIMITATION, recorded because the owner brief demands saying exactly
--       this: **service_role bypasses RLS, so RLS cannot save this table either.** Every
--       Edge Function executes as service_role (14-edge-function-security-audit.md:243-252,
--       Check 12 VERIFIED: "every function uses the service-role key, therefore RLS never
--       applies ... every handler is a trust boundary"); S2-EXEC-08 §2(5) :44 records the
--       live data path never depended on auth.uid() and RLS is defence-in-depth, not the
--       primary gate (finding S-1). Therefore the anti-confusion control ("a client must
--       never assert a Firebase UID and bind it to someone else's profile") is NOT a
--       policy on this table -- it is the Edge Function's duty under A13 clause 5
--       (S2-EXEC-08:117-119: "Server-side verification of the Firebase ID token in every
--       protected Edge Function. A client-supplied UID is never authoritative and never
--       establishes parent-child ownership"), discharged when IMP-5 re-authors the
--       functions under A7-R/A8-R. LIMITATION L-1: this schema cannot enforce that; the
--       grants make the table unreachable to clients, but a buggy Edge Function running
--       as service_role can write any row. The compensating design is that every such
--       row still has to pass THIS table's constraints (unique pair, unique reverse, FK,
--       CHECKs) and the read path honours the revocation predicate in both directions
--       (2.9), so a mis-bound row is detectable and revocable, not silently powerful.
--       LIMITATION L-2: with service_role, the supabase_user_id column is readable even
--       when revoked; the contract in SECTION 7 (read only active_supabase_user_id) must
--       be honoured inside the function. Both limitations are for the owner's A13/IMP-5
--       review, not papered over.

-- ============================================================================
-- SECTION 6 -- GRANTS / REVOKES  (3 active statements)
-- ============================================================================
-- Consistent with the captured grant posture (g1-q6-20261029.json.table_grants, 149 rows):
-- service_role holds 133 of the 149 with the identical seven-privilege set
-- `DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE`, is_grantable='NO' on
-- every row (no WITH GRANT OPTION anywhere -- S2-EXEC-04 check 7, quoted at A3:855-858);
-- authenticated holds the remaining 16 SELECT-only rows, and five tables hold NOTHING for
-- authenticated (SECTION 5(a)). This table follows the seven-privilege service_role form
-- verbatim (A3:887 and its 18 siblings) and takes the authenticated-side of the
-- five-secret-table precedent: zero client grants. MAINTAIN (PG17) included because all
-- 19 captured tables carry it for service_role (A3:923-941, g1-q1.table_acl letter 'm').
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.firebase_identity_mapping TO service_role;
  -- ev: g1-q6.table_grants uniform service_role set; A3:887 style. REFERENCES is required
  -- for the FK maintenance path on profiles. INSERT/UPDATE is the binding/revocation path.
GRANT MAINTAIN ON TABLE public.firebase_identity_mapping TO service_role;
  -- ev: A3:923-941 (19x); PG17 vocabulary per A3:15-16 server assumption.

-- Defense-in-depth against DEFAULT PRIVILEGES bleed. EVIDENCED concern: the captured
-- pg_default_acl shows a row {owner: postgres, schema: public, object_type: r(tables),
-- acl: "postgres=arwdDxtm/postgres, anon=Dxtm/postgres, authenticated=Dxtm/postgres,
-- service_role=arwdDxtm/postgres"} (g1-q6-20261029.json.default_acl[2]). If staging
-- mirrors production, a NEW table created by postgres could inherit anon/authenticated
-- DELETE+TRUNCATE+MAINTAIN from default privileges -- silently blowing the zero-grant
-- posture of SECTION 5(a). Staging's own default ACL is NOT CAPTURED (A3 operator
-- checklist item [5], A3:57-60, makes capturing it mandatory before A3 SECTION 9; this
-- file runs before anyone may assume the answer), so this single REVOKE pins the posture
-- regardless of the default-privilege state. It is the file's ONLY statement with no
-- active-statement REVOKE precedent (S2-EXEC-04 check 7 counted 0 REVOKEs in the
-- reconstruction) -- disclosed as such. DERIVED (not DESIGN): the capture silence is a
-- property of the reconstruction-fidelity exercise, not a prohibition; the brief
-- requires "GRANT/revoke statements consistent with the captured grant posture", and
-- nothing is more consistent with `anon=false`-style deny-all than an explicit revoke
-- when a default might contradict it. A redundant REVOKE (nothing granted) is a NOTICE,
-- not an error; in a BEGIN/COMMIT wrapper it cannot abort the batch.
REVOKE ALL ON TABLE public.firebase_identity_mapping FROM PUBLIC, anon, authenticated;
  -- ev: g1-q6.default_acl[2] (postgres-owned public-table defaults incl. anon/auth);
  --     A3:57-60 (staging prior state uncaptured); 14:139 ("because every handler runs
  --     as service_role, RLS cannot catch a missed scope predicate" -- privilege-level
  --     pinning is the layer that CAN catch a default-privilege surprise).
-- NO column-level GRANT UPDATE(...) statements are emitted: the 183 captured column
-- grants (g1-q6.update_column_grants; A3:943-945) exist to narrow authenticated's
-- UPDATE per column; authenticated has no table UPDATE here to narrow. Service_role's
-- table-level UPDATE already covers both mutable lifecycle columns
-- (status, credential_revoked_at). No sequence grants needed: uuid PK via
-- gen_random_uuid() creates no sequence (A3c:216-219 same ruling).

-- ============================================================================
-- SECTION 7 -- THE READ/WRITE CONTRACT (0 active statements -- prose + canonical SQL)
-- ============================================================================
-- This section creates nothing (no function: return types are not invented outside the
-- A3b ruling, A3b:28-31). It records the contract the Edge Functions (IMP-5, under
-- A7-R/A8-R + A13 clause 5) must implement, so reviewer and operator can hold one
-- definition of "authorises nothing".
--
-- BIND (server-side, post-verification only -- A13 :117-119):
--   INSERT INTO public.firebase_identity_mapping (provider, firebase_uid, supabase_user_id)
--   VALUES ('firebase', <sub claim VERIFIED from the decoded ID token>, <profile uuid>)
--   ON CONFLICT (provider, firebase_uid) DO NOTHING;   -- idempotent replay, S2-A1:168-170
--   ...the caller must then CONFIRM the row exists; a conflict on the reverse UNIQUE
--   (provider, supabase_user_id) means one profile already carries another UID -> deny,
--   never re-point. (Which is the merge-attack branch; no business logic is invented here
--   beyond the two ratified constraints' natural conflicts.)
--
-- RESOLVE (the ONLY documented read path -- canonical lookup):
--   SELECT active_supabase_user_id
--     FROM public.firebase_identity_mapping
--    WHERE provider = 'firebase' AND firebase_uid = <verified sub>;
-- Outcomes, each required by a §-clause:
--   * No row        -> NULL -> authorises NOTHING. EVIDENCED requirement: S2-EXEC-08:84
--                        verbatim "a `sub` with no `M-B` row authorises nothing".
--                        Absence of a row is the schema's own answer: there is no
--                        default, no fallback join, no broader SELECT sanctioned.
--   * Row revoked   -> active_supabase_user_id IS NULL (generated, 2.9) -> authorises
--                        NOTHING even with a valid, unexpired Firebase token -- A13
--                        :131 verbatim requirement, made the DEFAULT shape of the lookup
--                        rather than a WHERE clause. Fail mode mirrors the evidenced
--                        device primitive: requireDevice refuses on status != 'active'
--                        OR credential_revoked_at IS NOT NULL (14:153-157).
--   * Row active    -> the single profile uuid; identity for downstream authorization
--                        decisions is still the profile row (role from profiles.role
--                        read server-side, 14:122), never the UID itself.
-- REVOKING (the operational act A13 :130 "designed at the mapping row"):
--   UPDATE public.firebase_identity_mapping
--      SET status = 'revoked', credential_revoked_at = now(), updated_at = now()
--    WHERE provider = 'firebase' AND firebase_uid = <sub>;
--   One write, both signals set, biconditional CHECK keeps them set together; every
--   subsequent RESOLVE returns NULL from then on with no cache to purge at this layer.
-- ALL THREE statements run only inside Edge Functions on the service-role key (no
-- client reaches these; SECTION 5). They are contract text, NOT executed, NOT embedded
-- as functions -- nothing in this file has been run.

-- ============================================================================
-- SECTION 8 -- POST-LOAD VERIFICATION (10 READ-ONLY SELECTs; run AFTER COMMIT; V-1..V-10)
-- ============================================================================
-- Style: A3 SECTION 10 (A3:1256-1389) -- expected values are the counts THIS file's
-- statements imply, stated inline; any mismatch is written down, not accepted.
-- V-1  object exists with 9 columns, one generated -- expected: 9 rows, exactly one with
--      is_generated='ALWAYS' (active_supabase_user_id), 8 with 'NEVER'.
SELECT column_name, data_type, is_nullable, is_generated
  FROM information_schema.columns
 WHERE table_schema='public' AND table_name='firebase_identity_mapping'
 ORDER BY ordinal_position;
-- V-2  constraint census -- expected: contype p=1, u=2, c=5, f=1 -> 9 constraints,
--      matching SECTION 3's statement count.
SELECT c.contype, count(*) AS expected_p1_u2_c5_f1
  FROM pg_constraint c JOIN pg_namespace n ON n.oid=c.connamespace
 WHERE n.nspname='public' AND c.conrelid='public.firebase_identity_mapping'::regclass
 GROUP BY c.contype ORDER BY c.contype;
-- V-3  the two ratified UNIQUE keys, verbatim definitions -- expected: the pair key and
--      the reverse key exactly as SECTION 3 wrote them.
SELECT conname, pg_get_constraintdef(oid) FROM pg_constraint
 WHERE conrelid='public.firebase_identity_mapping'::regclass AND contype='u' ORDER BY conname;
-- V-4  FK binding proof -- expected: exactly 1 FK, referencing public.profiles via id
--      (confrelid='public.profiles'::regclass, referred col id). Proves this file loaded
--      AFTER the A3 schema load, since profiles is created only by it (A3:301-307,:413).
SELECT conname, confrelid::regclass AS referenced_table FROM pg_constraint
 WHERE conrelid='public.firebase_identity_mapping'::regclass AND contype='f';
-- V-5  generated-column definition survived -- expected: 1 row; the expression embeds
--      BOTH revocation signals (status + credential_revoked_at), the A13 :131 control.
SELECT attname, attgenerated FROM pg_attribute
 WHERE attrelid='public.firebase_identity_mapping'::regclass
   AND attname IN ('active_supabase_user_id','supabase_user_id');
-- V-6  indexes -- expected: 4 rows in pg_indexes (pkey + the 2 UNIQUE-backed + the 1
--      emitted btree); nothing re-emitted constraint-backed (SECTION 4 note).
SELECT indexname FROM pg_indexes WHERE schemaname='public'
   AND tablename='firebase_identity_mapping' ORDER BY indexname;
-- V-7  RLS posture -- expected: relrowsecurity=true, relforcerowsecurity=false,
--      consistent with all 19 captured rows (g1-q1).
SELECT c.relrowsecurity AS expected_true, c.relforcerowsecurity AS expected_false
  FROM pg_class c WHERE c.oid='public.firebase_identity_mapping'::regclass;
-- V-8  ACL census -- expected: aclexplode rows ONLY for the owner (postgres) and
--      service_role; zero rows naming anon or authenticated; is_grantable false on every
--      entry (g1-q6 posture). Companion privilege probes: authenticated SELECT -> false,
--      anon INSERT -> false, service_role INSERT -> true.
SELECT x.grantee::regrole::text AS grantee, x.privilege_type, x.is_grantable
  FROM pg_class c CROSS JOIN LATERAL aclexplode(c.relacl) x
 WHERE c.oid='public.firebase_identity_mapping'::regclass ORDER BY 1,2;
SELECT has_table_privilege('authenticated','public.firebase_identity_mapping','SELECT') AS expected_false,
       has_table_privilege('anon','public.firebase_identity_mapping','INSERT')          AS expected_false,
       has_table_privilege('service_role','public.firebase_identity_mapping','INSERT')  AS expected_true;
-- V-9  empty-store census -- expected: 0 rows. There are no approved fixtures (A14
--      unsigned, S2-EXEC-08 §6.3) and no authorised writer yet (A13 fence unsigned);
--      a non-zero answer here BEFORE step 2 of the §5 execution sequence is a red flag
--      to stop and investigate, not a pass.
SELECT count(*) AS rows_expected_0 FROM public.firebase_identity_mapping;
-- V-10 revocation-state-space proof -- expected: 0 rows even once fixtures exist; the
--      biconditional CHECK (SECTION 3) makes a half-revoked row unrepresentable.
SELECT count(*) AS inconsistent_expected_0 FROM public.firebase_identity_mapping
 WHERE (status = 'revoked') <> (credential_revoked_at IS NOT NULL);
COMMIT;                                  -- transaction control; not counted

-- ============================================================================
-- SECTION 9 -- ROLLBACK (ALL COMMENTED -- NOTHING HERE MAY BE PASTED WITHOUT ITS OWN
--               SEPARATE OWNER DECISION)
-- ============================================================================
-- Same honest position as A3 SECTION 11 (A3:1392-1427): Supabase Free/NANO has NO
-- platform backup and NO PITR for this project (00-stage2-execution-plan.md:155-159,
-- R-30/R-35), so rollback is a DROP-class forward action, not a restore; and no
-- statement here was ever executed or tested. This file is purely additive (one table,
-- its constraints/indexes, three privilege statements), so teardown is one step, in
-- reverse order; the table has NO inbound FKs (nothing references it), so nothing can
-- block the drop:
-- -- DROP INDEX public.firebase_identity_mapping_supabase_user_id_idx;   -- implicit under DROP TABLE; shown for order clarity
-- -- ALTER TABLE public.firebase_identity_mapping DISABLE ROW LEVEL SECURITY;
-- -- REVOKE ALL ON public.firebase_identity_mapping FROM service_role;   -- implicit under DROP TABLE
-- -- DROP TABLE public.firebase_identity_mapping;                        -- removes constraints incl. both UNIQUE-backed indexes; NO CASCADE
-- Do NOT run DROP SCHEMA-style rollbacks (A3:1415-1419: never offered, never verified).
-- If real binding rows ever existed at rollback time (post-A13+cutover, post-A14),
-- dropping this table deletes the external-identity bindings WITHOUT deleting the
-- profiles or auth.users rows -- the human keeps their Supabase identity; only the
-- bridge is removed. That asymmetry (drop = unlink, not delete-user) is deliberate and
-- mirrors ON DELETE CASCADE directionality (SECTION 3 FK). Record the torn-down state;
-- re-creation is this file re-run under fresh approvals.

-- ============================================================================
-- SECTION 10 -- WHAT THIS FILE DOES *NOT* SOLVE (owner brief requirement 10)
-- ============================================================================
-- N-1 THE §2(4) PROFILE-PROVISIONING GAP -- THE HARD ONE, NAMED, NOT SILENTLY FIXED.
--     No row in this table can be created by handle_new_user, because handle_new_user is
--     an AFTER INSERT trigger on auth.users and a third-party-JWT verification never
--     inserts into auth.users -- S2-EXEC-08:42 §2(4) states the chain verbatim;
--     S2-A1 §2.5 case S-1 (:226) states the consequence ("The trigger never fires; no
--     profile is ever created"). This file does NOT add any trigger to work around it.
--     WHY NOT -- the evidence question the brief asks: a trigger COULD in principle fire
--     on INSERT to this table and attempt auth.users/profiles creation, and I do not have
--     the evidence that would make it admissible: (i) creating an auth.users row from SQL
--     requires an admin-level write into the auth schema and "there is no in-repo evidence
--     that such a call exists or is permitted" (S2-A1 F-2, :185-188; all 9 catalogued
--     functions write nothing to auth.users); (ii) the provisioning ACTION itself is
--     expressly NOT authorised by A13 -- "DOES NOT AUTHORISE: Executing the
--     profile-provisioning gap at §2(4). No new or altered Edge Function action may be
--     created under this instrument" (S2-EXEC-08:121-123) -- and a trigger is exactly an
--     invented business-logic action, which §4's own rule (:94-95 lineage "do not invent
--     business logic") and the owner's open item §6.4 (:166, gap "approved by nobody")
--     reserve for a separate ruling (an A7-R addition or the operator pre-seeding path).
--     Practical reading for the owner: with this table loaded and §2(4) unresolved, the
--     bridge FAILS CLOSED for every Firebase sign-in -- no mapping row can appear, so
--     every `sub` is a no-row `sub`, which the ratified rule already defines as
--     "authorises nothing" (S2-EXEC-08:84). The gap becomes visible as zero logins, not
--     as a silent bypass. That is the correct, intended interim state.
-- N-2 THE ACTUAL BINDING WRITER. This file creates the store; it does not create or amend
--     any Edge Function. The verify-then-bind logic (SECTION 7) executes only once IMP-5's
--     re-authored functions under A7-R/A8-R exist and A13 clause 5 is implemented.
--     Verifier choice (V-1 Admin SDK / V-2 local JWKS / V-3 third-party bridge) is E-3
--     `[N]` -- S2-A1:532 -- an owner decision this schema stays neutral about.
-- N-3 WHETHER THIRD-PARTY JWTs REACH POSTGREST/RLS (§2(5), S2-EXEC-08:44) is not
--     established and this file assumes it does NOT: no policy here uses auth.uid(), no
--     client grant exists to protect. Re-check after cutover per §2(5); nothing here
--     pre-commits to that outcome.
-- N-4 THE DASHBOARD CONFIGURATION: the Third-Party Auth provider row (issuer/audience/
--     JWKS, S2-EXEC-08 §3) and the Email-provider disable cutover step (§2(2), :5) are
--     browser operations under the signed fence; SQL cannot and does not perform them.
-- N-5 FIXTURES AND SECURITY TESTS (invalid token, expired token, revoked mapping,
--     cross-family isolation) need A14 (S2-EXEC-08 §6.3); until then V-9's expected 0
--     rows stands and the revoked-row path can be proven by fixture-free reasoning only.
-- N-6 EMAIL AS MERGE KEY / manual-linking posture (S2-A1:171-174): unresolved by design;
--     the reverse-UNIQUE (D7) blocks one-profile-many-UIDs but says nothing about two
--     humans sharing an email -- no schema object here depends on that decision.
-- N-7 updated_at trigger maintenance (A3c O-3): copied shape, invented nothing, same
--     open decision as the other tables.

-- ============================================================================
-- SECTION 11 -- DESIGN REGISTER: EVERY "REQUIRES OWNER APPROVAL" ITEM IN ONE PLACE
-- ============================================================================
-- D1  Placement in public (not private) -- SECTION 1. Rejected: private-schema placement
--     (would inherit the M-4/D-5 USAGE question and the capture-divergence reasoning
--     A3c:195-205 already applied).
-- D2  FK to public.profiles(id) -- SECTION 2.4. Rejected: auth.users(id) per the
--     S2-A1:155 sketch (name `supabase_user_id` kept anyway for spec fidelity).
-- D3  firebase_uid length 1..128 + alphanumeric regex -- SECTION 2.3. No repo sample
--     exists (E-4 `[N]`); bound from A3:461/:435 precedents. Rejected: exact-{128} regex.
-- D4  status domain {'active','revoked'} only (no 'pending') -- SECTIONS 2.5/3.
--     Rejected: devices-style 3-value domain with no evidenced producer for 'pending'.
-- D5  Biconditional revoked<=>timestamp CHECK -- SECTION 3. Rejected: devices-style
--     one-way consistency check (A3:464 precedent kept as the alternative).
-- D6  Stored generated column active_supabase_user_id as the fail-closed resolution --
--     SECTION 2.9. First generated column in the programme (none among the 183 captured).
--     Rejected: bare two-column lookup + caller discipline; boolean enabled flag;
--     SECURITY DEFINER lookup function (return-type invention + exposure unverified).
-- D7  UNIQUE (provider, supabase_user_id) -- reverse 1:1, SECTION 3. Rejected:
--     many-to-one per strict literal reading of "one unique mapping" (uid side only).
-- D8  Zero client grants + explicit REVOKE vs the 14-of-19 authenticated-SELECT pattern
--     -- SECTIONS 5/6. Follows the five-secret-tables precedent (g1-q6); REVOKE has no
--     active-statement precedent and is disclosed as posture-pinning, not capture.
--     (D8's REVOKE was argued DERIVED, not invented-from-nothing: g1-q6.default_acl[2].)
-- D9  Object name firebase_identity_mapping -- the table has no evidenced name (M-B is a
--     diagram label, S2-A1:503). Chosen self-describing name; rejected literal `m_b`
--     (opaque in pg_tables) and `identity_bridge` (S2-A1 §2.2 uses "identity-bridge" as a
--     description, not a name).

-- ============================================================================
-- STATUS / STATEMENT CENSUS (this file)
-- ============================================================================
-- Active (execute-on-paste) statements: 16 total --
--   SECTION 0: 1 sentinel DO        SECTION 2: 1 CREATE TABLE (9 columns)
--   SECTION 3: 9 ALTER ... ADD CONSTRAINT (1p, 2u, 5c, 1f)
--   SECTION 4: 1 CREATE INDEX       SECTION 5: 1 ALTER ENABLE ROW LEVEL SECURITY
--   SECTION 6: 2 GRANT + 1 REVOKE
-- Wrapped in one BEGIN/COMMIT (mirrors A3 M-1 repair rationale, A3:77-97: an abort
-- leaves nothing half-built; no IF NOT EXISTS anywhere, so a re-run after a committed
-- load fails 42P07 at the CREATE TABLE -- do not retry; tear down via SECTION 9 instead).
-- Read-only verification: SECTION 8, 12 SELECTs (V-1..V-10 incl. the two companion
-- privilege probes). Commented-only: SECTION 7 contract, SECTION 9 rollback.
-- Dependencies: A2'(a) executed (sentinel), A3 load committed (profiles). A13 fence
-- signed before paste. NOT EXECUTED, NOT RUN AGAINST ANYTHING, STAGING ONLY.
-- Deviations from capture conventions, itemised for review: (1) generated column (D6);
-- (2) explicit REVOKE (D8); (3) table name (D9); (4) status domain smaller than devices'
-- (D4); (5) biconditional consistency (D5). Everything else restates evidenced shapes.
-- ============================================================================
