# S2-A4 — Supabase Edge Functions audit (offline, repository-only)

**Record ID:** S2-A4
**Audit class:** OFFLINE, REPOSITORY-ONLY audit of the Supabase Edge Function lane. No cloud state was read, created or
changed.
**Date:** 2026-11-03.
**Verdict:** **`EDGE LANE HAS NO EVIDENCE BASE FOR THE OWNER'S BRIEF`** — the nine function names in the owner's brief
have **zero** occurrences anywhere in this repository, and the repository's only Edge Function inventory names a
**disjoint** set of nine. Nothing in the brief's set is `CONFIGURED`, `PLANNED` from evidence, or deployable. Every
evidenced function is `BLOCKED` behind A7 → A3 → A9 → A8.
**Operational actions performed by this audit: NONE.** No browser, no dashboard, no console, no CLI, no REST/API call, no
direct DB connection, no SQL, no deployment, no secret created/read/listed, no Firebase action, no production access of
any kind (including catalogue-only — A1 `INOPERATIVE`, C2b/R-43). Operations used: file reads, `ls`, `wc`, `grep`,
`sha256sum`, and local read-only Python parsing of JSON evidence files. **Exactly one new file was created: this one. No
existing file was modified. No git operation was performed.**

---

## 0. Label and status conventions

**Status vocabulary** (the only values used in Status columns, per the tasking):
`NOT STARTED` · `PLANNED` · `BLOCKED — APPROVAL REQUIRED` · `IN PROGRESS` · `CONFIGURED` · `VERIFIED` · `FAILED` ·
`NOT APPLICABLE`.

A `Status` cell carries **only** a value from the list above, or the task-mandated silence marker
**`MISSING — SOURCE EVIDENCE ABSENT`**. Where a cited record uses its own vocabulary (`NOT CREATED`, `NOT VERIFIED`,
`NOT TESTED`, `NOT LOAD-READY`, `PROPOSED — NOT APPLIED`, `BLOCKED — EDGE SOURCE REQUIRED`, `NOT PRESENT IN EVIDENCE`,
`RATIFIED`), that phrase is quoted **verbatim with its file:line** in the evidence cell, and the Status column is the
mapped value from the list above. Nothing is `CONFIGURED` or `VERIFIED` in this file unless a cited observation is named.

**Split labels** (§11): **Verified** · **Inferred** · **Missing evidence** · **Unverified** · **Recommendations**.

**Gate state carried in unchanged** (this audit authorises nothing): **A2′(a)**, **A2′(b)**, **A3**, **A9**, **A12 are
unsigned** ([04](04-risks-rollback-approvals.md):205); **A5 approved-but-not-executable** ([04](04-risks-rollback-approvals.md):213);
**A1 `INOPERATIVE`** ([00](00-stage2-execution-plan.md):87, `:90`); **A0 approved as a recorded decision, fence unfilled**
([04](04-risks-rollback-approvals.md):209); ratification is **option (i) and grants nothing forward**
([approval-package-v2](approval-package-v2-ratification-and-forward.md):123-127, `:131`). **A7** and **A8** exist as approval
rows ([04](04-risks-rollback-approvals.md):215-216) with **no dated signature recorded anywhere** — the 2026-11-02 status
stamp enumerates only "A2′, A3, A9, A12 unsigned" ([04](04-risks-rollback-approvals.md):205), so A7/A8 are recorded here as
`BLOCKED — APPROVAL REQUIRED` on the basis that no signature exists in evidence, and their absence from the stamp list is
disclosed rather than read as a signature. **The owner's architecture direction is not a gate and overrides none of
these.**

---

## 1. Evidence base

| # | Artefact | Bytes / lines | SHA-256 (full, computed locally by this audit where marked ✚) | What it is |
| --- | --- | --- | --- | --- |
| E1 | `docs/stage1/evidence/edge-functions/capture-20261030.json` | 14,118 B / 178 L | ✚ `95ebe57cf6d0aa069113cfe5b1c10cf4d2cd739b8c326b63b3187b886a39ce33` | **The only Edge Function inventory in the repository.** 9 slugs + 6 `_shared/*.ts` modules, read from the **production** dashboard Monaco editor on 2026-10-30 (`capture.project` = `parent-control-prod`, `capture.ref` = `hhqgreaoqulmfwfwarhc`, `capture.method` at `:7`) |
| E2 | `docs/stage1/evidence/edge-functions/pairing/` | **empty directory** (0 entries) | n/a | Named as a location by `E1`'s `capture.operations_performed` `:10`; contains no file. Cross-confirmed at [S2-EXEC-05-complete-stage1-evidence-inventory.md](S2-EXEC-05-complete-stage1-evidence-inventory.md):36, `:335` |
| E3 | `docs/stage1/13-edge-function-source-inventory.md` (193 L) | — | — | Inventory + provenance + digests + §7 export procedure. `:24` "**The repository contains no Edge Function source in any form**" |
| E4 | `docs/stage1/14-edge-function-security-audit.md` (432 L) | — | — | 17-check security review of the same 9 functions |
| E5 | `docs/stage1/15-edge-function-test-plan.md` (235 L) | — | — | `:3` status **`NOT EXECUTED`**; 104 HTTP cases |
| E6 | `docs/stage1/16-phase-e-findings.md` (546 L) | — | — | Findings E1–E14 incl. E12 cron replay |
| E7 | `docs/stage1/evidence/functions-and-triggers.md` (120 L) | — | — | Pre-G1 dashboard note + 2026-10-30 amendment; §3 is a **source-form scan**, not an inventory of a different set |
| E8 | `docs/stage1/evidence/g1-b3b-20261029.json` | `inventory.rows` = **38**, `bodies` = **14** | — | **Postgres** function catalogue (24 `private` + 14 `public`). **Not** Edge Functions |
| E9 | `docs/stage1/evidence/g1-q10-20261029.json` | `functions` = **14** | — | **Public Postgres RPC inventory** — confirmed by key inspection (E8 note). Not an Edge Function list |
| E10 | `docs/stage1/evidence/g1-q9-20261029.json` | `source.endpoint` = "dashboard Advisor page … run-lints call" | — | **Security-Advisor lint capture** (33 occurrence-rows, 5 rules). Not an Edge Function list |
| E11 | `docs/stage1/06-secrets-and-environments.md` (130 L) | — | — | Secret placement/rotation register, names only |
| E12 | `docs/stage2/evidence/S2-INSP-03-read-only-reconfirmation.md` | — | — | `:88-91` staging `/functions` page → "Edge function cannot be found in your project" ⇒ **0 deployed functions**; `:192` `VERIFIED`; `:224` `Deploy a new function` **visible, not clicked** |
| E13 | `docs/stage2/S2-EXEC-04-a3-precondition-matrix.md` | — | — | The `NOT LOAD-READY` state this lane depends on (§3) |
| E14 | `C:/Users/ASUS/.qoder/tmp/D--control/g3-build/{90-limitations.md, 91-coverage.md}` | cited as `g3-build/…` | `g3-reconstruction-2026-11-02.sql` raw-byte digest `fc996f450690d8b6…` (`90-limitations.md`:159; reproduced in [S2-EXEC-04-a3-precondition-matrix.md](S2-EXEC-04-a3-precondition-matrix.md):40) | The reconstruction artefact **of record**, outside the repository by design (`90-limitations.md`:134 L-10). Read-only only |
| E15 | `docs/stage1/02-architecture.md`, `docs/stage1/01-baseline-inventory.md`, `firebase/SETUP-CHECKLIST.md`, `docs/stage2/{00,01,04,05,06}`, `approval-package-v2`, parts `A`/`F`/`I`/`J`, `S2-REVIEW-03`, `S2-EXEC-05-*` | — | — | Narrative + gate + split-analysis sources, cited inline |

**PII discipline.** E12/E1 and the identity note at `docs/stage2/evidence/S2-INSP-02-firebase-console.md:17` and `:42-46`
contain operator account names, email addresses and an account-mask. **None is reproduced here** — cited by file + line +
type ("operator Google account identifier", "retired Firebase CLI account mask"). No secret value, key, JWT, token,
password, connection string or credential-bearing URL appears in this file. No function body is pasted anywhere: source
availability is expressed as char counts, digests and named anchors only.

---

## 2. Finding of record: the brief's nine names vs the evidence's nine names

Repo-wide, case-insensitive search of every tracked file (excluding `.git/`) for each of the nine names in the owner's
brief, and for the hyphenless/underscore variants:

| Brief name | Occurrences in this repository | Result |
| --- | --- | --- |
| `notification-cron` | **0** | `MISSING — SOURCE EVIDENCE ABSENT` |
| `notification-queue` | **0** | `MISSING — SOURCE EVIDENCE ABSENT` |
| `process-queue` | **0** | `MISSING — SOURCE EVIDENCE ABSENT` |
| `process-scheduled` | **0** | `MISSING — SOURCE EVIDENCE ABSENT` |
| `register-token` | **0** | `MISSING — SOURCE EVIDENCE ABSENT` |
| `send-email` | **0** | `MISSING — SOURCE EVIDENCE ABSENT` |
| `send-whatsapp` | **0** | `MISSING — SOURCE EVIDENCE ABSENT` |
| `send-push` | **0** | `MISSING — SOURCE EVIDENCE ABSENT` |
| `verify-firebase-token` | **0** | `MISSING — SOURCE EVIDENCE ABSENT` |

Corroborating negative searches (0 hits each): `smtp` / `sendgrid` / `resend.co` / `mailgun` / `ses` as a mail service;
`whatsapp`; `twilio`; `fcm` as a function; `push_token`; any queue/outbox table name. The only Firebase-token-adjacent
terms in the repo are *placement rules* for a service-account key that does not exist
([02-architecture.md:135](../stage1/02-architecture.md), [06-secrets-and-environments.md:20](../stage1/06-secrets-and-environments.md))
and the *negative* statements listed below.

**The repository independently negates the brief's set**, in its own words:

* `firebase/SETUP-CHECKLIST.md:100` — "**No Edge Function currently sends FCM**; the 9 deployed functions are pairing,
  registration, policy, command, telemetry, family admin, remote session, auth bootstrap and cron."
* `docs/stage1/01-baseline-inventory.md:63-65` — "## 3. Edge Functions (9, deployed 2–3 days before capture)" then the
  explicit nine: `auth-bootstrap`, `cron`, `device-command`, `device-policy`, `device-register`, `device-telemetry`,
  `family-admin`, `pairing`, `remote-session`.
* `docs/stage1/02-architecture.md:177` — "Dedicated state-fetch function | PROPOSED | **No function by that name among
  the 9**".
* `docs/stage1/00-status-register.md:35` — "all 9 deployed Edge Functions (`pairing`, `auth-bootstrap`, `device-command`,
  `device-register`, `device-policy`, `device-telemetry`, `family-admin`, `remote-session`, `cron`)".
* [S2-EXEC-05-complete-stage1-evidence-inventory.md](S2-EXEC-05-complete-stage1-evidence-inventory.md):155-157 — "The
  real inventory is `edge-functions/capture-20261030.json` (9 slugs: `pairing`, `auth-bootstrap`, `device-command`,
  `device-register`, `device-policy`, `device-telemetry`, `family-admin`, `remote-session`, `cron`)".

**Intersection: 0 of 9. Overlap: none.** The brief's `cron`-like and `push`-like intentions have *nearest evidenced
analogues* (see §2.4) but no evidenced identity.

### 2.1 Evidence-based inventory — the functions the evidence actually names

Source-form key: **present** = editor text captured with char count + SHA-256; **absent** = nothing in the repository.
"Deployed (prod)" describes the 2026-10-30 historical capture surface. "Deployed (staging)" is the 2026-11-02T07:16Z
observation. **Never paste the body; char counts and digests only.**

| # | Name | Evidence source (file:line / JSON key) | Source-code text in evidence | Deployed (prod, 2026-10-30) | Deployed (staging) | Auth requirement (evidenced) | Database dependency (evidenced) | Firebase dependency | Secrets/env **by name only** | Error handling / retry if evidenced |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `pairing` | E1 `functions[0]` `:26-42`; E3 `:56`; E4 §1 | **Present (readable TS)** — 33,993 chars / 972 lines; `sha256 427d419d4f691cfb…` (`:30`). Editor text only; **not** in the repo (`E3:20` `supabase/functions/` = no) | Code view served for the slug ⇒ `VERIFIED` *as at capture*; "editor text = deployed bytes" is **`INFERRED`** (E3 `:134-137`) | `NOT STARTED` (`E12:88-91`, `:192`) | User JWT; parent-or-child role per action; family membership per action (`:32`); `requireVerifiedEmail` per E7 `:80` | RPCs `create_pairing_request`, `create_pairing_invite`, `respond_pairing_request`, `unlink_child`; tables `pairing_requests`, `pairing_attempts`, `device_pairing_tokens`, `child_contact_ids`, `families`, `family_members`, `profiles`, `audit_logs` | **`NOT APPLICABLE`** — no Firebase reference in E1/E3/E4 | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `PAIRING_HASH_PEPPER` (E3 `:150-151`; `parts/F-e6-e7.md:23` `Deno.env.get("PAIRING_HASH_PEPPER")`) | Uniform `INVALID_IDENTIFIER` (`:585-599`); `rate_limit.ts` pairing quotas (E1 `:169`); `ApiError`→ generic 500, `error.name` logged only (E1 `:168`); `audit_failed` 500 fails the request (E1 `:165`); 1 catch block (E7 `:80`); **retry behaviour: `MISSING — SOURCE EVIDENCE ABSENT`** |
| 2 | `auth-bootstrap` | E1 `functions[1]` `:44-56`; E3 `:57` | **Present (readable TS)** — 4,302 chars / 140 lines; `sha256 34cf673247a61a91…` (`:48`) | As row 1 | `NOT STARTED` | User JWT + verified email; `set_role` self-only one-time from `unset`; `create_family` parent-only (`:50`) | RPC `create_family_with_owner`; `profiles.update` scoped `.eq(id, auth.user.id)`; `child_contact_ids` upsert "(best effort)" (`:53`, `:72-80`); `audit_logs` | **`NOT APPLICABLE`** | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` | `ensureNoError`; best-effort `child_contact_ids` upsert is the only evidenced non-fatal path (`:72-80`); **retry: absent** |
| 3 | `device-command` | E1 `functions[2]` `:58-71`; E3 `:58` | **Partial** — minified 2-line bundle; 18,124 chars; `sha256 4e31901a2891986b…` (`:62`). Original module boundaries/comments `NOT VERIFIED` (E3 `:141-147`) | As row 1 | `NOT STARTED` | `create`: parent JWT + verified email + `requireActiveDeviceForParent`; `poll`/`ack`: `x-device-id` + `x-device-secret` (`:64`) | RPCs `apply_policy_version`, `poll_device_commands`; tables `device_commands`, `device_policies`, `devices` (`:67-69`) | **`NOT APPLICABLE`** | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` | Idempotency key 1–128 chars, pre-insert lookup, `23505` → re-read (`:67`); ack terminal-status short-circuit + `.in(status,[pending,delivered])` (`:69`); `expire_stale_commands` exists in E8 catalogue but **no evidenced caller** ⇒ `MISSING — SOURCE EVIDENCE ABSENT`; retry: absent |
| 4 | `device-register` | E1 `functions[3]` `:73-84`; E3 `:59` | **Partial** — minified; 9,086 chars; `sha256 712d46b076b11ced…` (`:77`) | As row 1 | `NOT STARTED` | Child JWT + verified email + `assertChildMembership(body family_id)` (`:79`) | **No RPC evidenced.** Direct `insert`/`update` on `devices`; reads `pairing_requests` ("revoked device + later approved pairing"), `audit_logs` (`:82-83`) | **`NOT APPLICABLE`** | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` | `409 device_exists` on child mismatch; `device_registration_blocked`; response strips `secret_hash` + `installation_id` (`:82`); **one raw PostgREST error path thrown** (non-`23505` insert) — safe via the fixed 500 but inconsistent (E4 `:280-281`); retry: absent |
| 5 | `device-policy` | E1 `functions[4]` `:86-97`; E3 `:60` | **Partial** — minified; 11,174 chars; `sha256 3efdb19b7159fce8…` (`:90`) | As row 1 | `NOT STARTED` | Parent JWT + verified email + `requireActiveDeviceForParent` (`:92`) | RPC `apply_policy_version`; `devices`, `device_policies` (`:95`) | **`NOT APPLICABLE`** | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` | Strict key allowlists, arrays ≤200, `app_rules` ≤100, policy JSON ≤256 KB (`:95`); idempotent result skips audit (`:96`); RPC errors mapped by substring to fixed messages, RPC message never returned (E4 `:277-279`); retry: absent |
| 6 | `device-telemetry` | E1 `functions[5]` `:99-113`; E3 `:61` | **Partial** — minified; 12,461 chars; `sha256 b3ca5221347a5f75…` (`:103`) | As row 1 | `NOT STARTED` | **Device only** (`x-device-id` + `x-device-secret`); `device_id`/`family_id` always from the authenticated device row (`:105`) | RPC `replace_device_apps`; tables `devices`, `usage_daily`, `location_events`, `safe_zones`, `safe_zone_states`, `safety_alerts`, `device_apps` (`:108-111`) | **`NOT APPLICABLE`** | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` | Upserts for dedupe (`:109`, `:110`); `location_events` is a **plain insert → retried uploads duplicate** (E4 `:314-316`); **writes no `audit_logs` rows at all** — `VERIFIED` (E3 `:110-112`, finding E13); low-battery alert deduped in a 6 h window (`:108`); retry: absent |
| 7 | `family-admin` | E1 `functions[6]` `:115-130`; E3 `:62` | **Partial** — minified; 9,386 chars; `sha256 b6864fdda7ad52ff…` (`:119`) | As row 1 | `NOT STARTED` | Parent JWT + verified email for all five actions; `update_retention` additionally owner-only (`:121`) | RPCs `revoke_device`, `request_device_recovery`; tables `safety_alerts`, `location_events`, `usage_daily`, `families`, `audit_logs` (`:124-128`) | **`NOT APPLICABLE`** | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` | `purge_data` cutoff-based ⇒ naturally idempotent (`:127`, E4 `:312`); retention floor = max(requested, configured); **handler-level authorisation for `revoke_device` is `NOT VERIFIED`** — delegated to `private.revoke_device`, one of the 24 unread bodies (E4 `:53-55`, `:149-151`); retry: absent |
| 8 | `remote-session` | E1 `functions[7]` `:132-148`; E3 `:63` | **Partial** — minified; 12,848 chars; `sha256 85e30c3c6da5d279…` (`:136`) | As row 1 | `NOT STARTED` | User JWT + verified email; parent→`request`, child→`pending_child`/`respond`/`start`, either participant→`end`/`ice` (`:138`) | **Direct `INSERT` into `remote_sessions`, bypassing `public.request_remote_session`** (`:141`, finding E4); `devices`, `families`, `audit_logs`; `webrtc_signals` is in the 19-table set but **no evidenced write to it** | **`NOT APPLICABLE`** | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, **`TURN_SECRET`** (`:146` TURN credential HMAC-SHA1), `STUN_URL`/`TURN_URL` (E3 `:151`) | Compare-and-set on every transition + `409 session_not_open`; idempotent replays return 200 (`:143-145`; E4 `:205-207`); consent gate before ICE, TTL clamp 60–86400 s default 600 (`:146`); `request` has **no rate limit** (E4 `:199`, finding E7); retry: absent |
| 9 | `cron` | E1 `functions[8]` `:150-162`; E3 `:64` | **Partial** — minified; 3,791 chars; `sha256 4cb4bd11e2844623…` (`:154`) | As row 1 | `NOT STARTED` | **No JWT.** Shared secret header `x-cron-secret`; `CRON_SECRET` must be ≥16 chars else `503 cron_not_configured` (`:156`) | RPCs `expire_stale_sessions()`, `detect_offline_devices()` (`:160`); tables `remote_sessions`, `devices` (by effect) | **`NOT APPLICABLE`** | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, **`CRON_SECRET`** (`:156`) | SHA-256 both sides + constant-time hex compare; missing/empty/mismatch → `401` (`:159`); actions idempotent maintenance RPCs ⇒ replay impact bounded (E4 `:326`; E6 `:452-454`); static secret, **no timestamp/nonce/IP allowlist** (finding E12); retry: absent |
| 10–18 | `notification-cron`, `notification-queue`, `process-queue`, `process-scheduled`, `register-token`, `send-email`, `send-whatsapp`, `send-push`, `verify-firebase-token` | **No source.** Negative result recorded in §2 | **Absent** — 0 occurrences; no digest, no char count, no slug, no anchor | `NOT STARTED` (cannot be assessed; production surface not re-observable — A1 `INOPERATIVE`) | `NOT STARTED` (`E12:88-91` shows 0 functions of any slug) | `MISSING — SOURCE EVIDENCE ABSENT` | `MISSING — SOURCE EVIDENCE ABSENT` | `MISSING — SOURCE EVIDENCE ABSENT` | `MISSING — SOURCE EVIDENCE ABSENT` | `MISSING — SOURCE EVIDENCE ABSENT` |

**Count of functions the evidence supports: 9.** (The brief asserts 9; the sets are disjoint.)

### 2.2 Shared modules — evidenced, but not functions

These are **modules**, not deployables, and they are where the auth logic the owner cares about lives.

| Module | Evidence | Chars / lines | SHA-256 (E1 `shared[]`) | Role in the Firebase question |
| --- | --- | --- | --- | --- |
| `_shared/auth.ts` | E1 `:166`; E3 `:86` | 9,920 / 338 | `34b46f5a302f5a6a…` | **The entire identity boundary**: `getServiceClient` (service role), `bearerToken`, `requireUser` = `db.auth.getUser`, `requireRole`, `assertFamily*`, `requireActiveDeviceForParent`, `requireDevice` |
| `_shared/validation.ts` | E1 `:170`; E3 `:88` | 12,640 / 419 | `3b81768322eb5aad…` | `identifierHash` = HMAC with `PAIRING_HASH_PEPPER` with **silent fallback to SHA-256** (finding E6); constant-time helpers |
| `_shared/rate_limit.ts` | E1 `:169`; E3 `:89` | 7,148 / 211 | `754502ef27b6f29f…` | Pairing-only quotas; "all counts are read-then-act" (finding E8) |
| `_shared/envelope.ts` | E1 `:168`; E3 `:87` | 3,517 / 112 | `cf4a69115b6fd94a…` | `ApiError`, generic 500, `readJson` 512 KB cap, `ensureNoError` |
| `_shared/audit.ts` | E1 `:165`; E3 `:90` | 1,101 / 38 | `649d277ed6358d11…` | `recordAudit` inserts `audit_logs` with a **caller-supplied** `actor_user_id`; throws `audit_failed` (E4 `:293`) |
| `_shared/cors.ts` | E1 `:167`; E3 `:91` | 490 / 13 | `33ec5b77c5f14bae…` | `Access-Control-Allow-Origin: *`; allow-headers list names `authorization`, `x-device-secret`, `x-cron-secret` (finding E9) |

Total evidenced editor text: **115,165 chars** across the nine function entries + **34,816 chars** across the six shared
modules (summed from E1 `len` fields). `rate_limit.ts` exists only in the `pairing` tree; bundles inline only the helpers
they call (E3 `:93-94`).

### 2.3 Evidence that names functions the brief omits

The brief omits **all nine** evidenced names. Specifically material omissions:

* **`auth-bootstrap`** — the *only* evidenced function that provisions identity-adjacent state (`profiles.role`,
  `create_family_with_owner`, `child_contact_ids`). Under "Firebase handles Auth" this is the single most affected
  evidenced function, and the brief does not mention it. (E1 `:44-56`)
* **`pairing`** — the largest handler (33,993 chars, 9 actions) and the only one carrying rate limits. Omitted. (E1 `:26-42`)
* **`cron`** — the only evidenced scheduled worker. Omitted, while two *other* cron-like names are asserted. (E1 `:150-162`)
* **`device-register`** — the only evidenced device-provisioning function. The brief's `register-token` is a near-neighbour
  but is not the same thing: `device-register` registers a device with a **client-chosen secret hash** (finding E10), not a
  push token, and E1 `:82` shows no push-token field in its payload.
* **The six `_shared/*.ts` modules** — omitted entirely from the brief, yet they hold every auth primitive.

### 2.4 Nearest evidenced analogues (explicitly **not** identity)

| Brief name | Closest evidenced thing | Status of the mapping |
| --- | --- | --- |
| `notification-cron` | `cron` (actions `expire_sessions`, `detect_offline`) | **`NOT APPLICABLE` as identity.** Evidenced `cron` performs **no notification work**: its only two RPCs are session expiry and offline detection (E1 `:155`, `:160`) |
| `process-scheduled` | `cron`; `private.expire_stale_commands` (catalogue E8, caller unevidenced) | `MISSING — SOURCE EVIDENCE ABSENT` |
| `notification-queue` / `process-queue` | `device_commands` (poll/ack state machine) | **No queue table exists.** Among the 19 captured tables (E8-era `g1-q1`, 19 rows) there is no queue/outbox table; `deletion_jobs` is recorded **MISSING** and a deletion-job queue is `PROPOSED — NOT APPLIED` ([03-data-model.md:47](../stage1/03-data-model.md), `:110`, `:177`) |
| `send-push` | Nothing. `[02-architecture.md:176](../stage1/02-architecture.md)` "Edge Function → FCM send path | **PROPOSED** … nothing written" | `MISSING — SOURCE EVIDENCE ABSENT` |
| `register-token` | `[02-architecture.md:103-104](../stage1/02-architecture.md)` steps 4–5 are **design only**; `SETUP-CHECKLIST.md:99` "**There is no `push_tokens` table and no token column on `devices` today**" | `MISSING — SOURCE EVIDENCE ABSENT` — and **no database home exists** |
| `send-email`, `send-whatsapp` | Nothing. Mail/SMS providers are not named in any evidence file | `MISSING — SOURCE EVIDENCE ABSENT` |
| `verify-firebase-token` | Nothing. See §5 | `MISSING — SOURCE EVIDENCE ABSENT` |

---

## 3. Function → Postgres dependency matrix

### 3.1 What the reconstruction artefact emits today

Cited from `g3-build/90-limitations.md` and `g3-build/91-coverage.md`, both read-only, and cross-confirmed at
[S2-EXEC-04-a3-precondition-matrix.md](S2-EXEC-04-a3-precondition-matrix.md):99 and [00-stage2-execution-plan.md](00-stage2-execution-plan.md):166.

| Object class | Captured in evidence | **Emitted as executable by the artefact** | Cite |
| --- | --- | --- | --- |
| Schemas | 2 | 2 | `91-coverage.md`:9 |
| Tables | 19 | 19 | `91-coverage.md`:10 |
| Columns | 183 | 183 | `91-coverage.md`:11 |
| Constraints | 137 | 137 | `91-coverage.md`:12 |
| Indexes | 62 | 34 (28 suppressed as duplicate-of-constraint) | `91-coverage.md`:13 |
| **Functions** | **38** | **0** | `91-coverage.md`:14 — "**0 executable.** … DDL impossible without a return type" |
| — bodies recovered | 14 | **0** (comment text only) | `91-coverage.md`:15 |
| — bodies absent | 24 | **0** | `91-coverage.md`:16 |
| — **return types** | **0 of 38 captured** | n/a | `91-coverage.md`:17 "**The root blocker of this artefact**"; `90-limitations.md`:34-37 |
| Triggers on `public` | 7 | **0** | `91-coverage.md`:18 |
| Trigger on `auth.users` | 1 | **0** | `91-coverage.md`:19 |
| RLS enablement | 19 | 19 `ENABLE ROW LEVEL SECURITY` | `91-coverage.md`:20 |
| **RLS policies** | **21** | **0** | `91-coverage.md`:21 |
| Realtime publication tables | 4 (documentary, `INFERRED FROM DOCUMENTATION`) | **0** | `91-coverage.md`:28 |
| Extensions (incl. `pg_cron`) | **UNKNOWN — never captured** | 0 | `91-coverage.md`:27; `90-limitations.md`:62 |
| **Total active statements** | — | **459**, of which **0** create a function / trigger / policy / publication | `90-limitations.md`:18-22 |

**Verdict of record:** artefact is **`NOT LOAD-READY` by construction** (`90-limitations.md`:14), and the load itself is
gated on **A3 — unsigned** ([04](04-risks-rollback-approvals.md):212; [S2-EXEC-04-a3-precondition-matrix.md](S2-EXEC-04-a3-precondition-matrix.md):38 M-04).
Staging today has **0 tables** (`E12:192`, `:85-86`).

### 3.2 Per-function dependency table

"RPC required" is read from E1 `anchors`. "Works after a signed A3 structural-only load?" assumes M-20's
structural-only outcome (§3.1).

| Function | RPCs required | `private.*` required (0 of 24 bodies captured) | Tables required | **Executable objects missing** | Works today? |
| --- | --- | --- | --- | --- | --- |
| `pairing` | `create_pairing_request`, `create_pairing_invite`, `respond_pairing_request`, `unlink_child` | `private.create_pairing_request` (**unread**), `private.create_pairing_invite` (**unread**), `private.respond_pairing_request` (**unread**), `private.unlink_child` (read, 2,514 chars, E8 `bodies`) | `pairing_requests`, `pairing_attempts`, `device_pairing_tokens`, `child_contact_ids`, `families`, `family_members`, `profiles`, `audit_logs` | 4 functions + `audit_logs_append_only` trigger + 21 policies | **No** — undefined-function error at first RPC |
| `auth-bootstrap` | `create_family_with_owner` | `private.create_family_with_owner` (**unread**) | `profiles`, `families`, `child_contact_ids`, `audit_logs` | 1 function + `profiles_before_update`, `families_before_update`, `set_updated_at` triggers | **No** |
| `device-command` | `apply_policy_version`, `poll_device_commands` | `private.apply_policy_version` (**unread**), `private.poll_device_commands` (**unread**) | `device_commands`, `device_policies`, `devices` | 2 functions + triggers + policies | **No** |
| `device-register` | **none evidenced** | — | `devices`, `pairing_requests`, `audit_logs` | `devices_set_updated_at` trigger; policies | **Partially — INFERRED.** It is the only evidenced function with no RPC call, so its table writes would run under `service_role` (which bypasses RLS: `90-limitations.md`:112). Its `updated_at` maintenance and its audit-row protection degrade because 0 triggers exist. **Not verified — nothing has been loaded or invoked** |
| `device-policy` | `apply_policy_version` | `private.apply_policy_version` (**unread**) | `devices`, `device_policies`, `device_commands` | 1 function + triggers + policies | **No** |
| `device-telemetry` | `replace_device_apps` | `private.replace_device_apps` (**unread**) | `devices`, `usage_daily`, `location_events`, `safe_zones`, `safe_zone_states`, `safety_alerts`, `device_apps` | 1 function + `safe_zone_states_set_updated_at` + policies | **No** |
| `family-admin` | `revoke_device`, `request_device_recovery` | `private.revoke_device` (**unread** — E4 `:53-55`, `:149-151`), `private.request_device_recovery` (read, 1,146 chars) | `devices`, `safety_alerts`, `location_events`, `usage_daily`, `families`, `audit_logs` | 2 functions + triggers + policies | **No** |
| `remote-session` | none via RPC (**deliberately bypasses `public.request_remote_session`**, E1 `:141`) | — (relies on `private.remote_session_transition_guard` **trigger**, read 226 chars, but the trigger is 0-of-7 emitted) | `remote_sessions`, `devices`, `families`, `audit_logs` | `remote_sessions_transition_guard` trigger + policies. **The E4 single-session invariant is unenforceable without the trigger** ([04](04-risks-rollback-approvals.md):27 R-05) | **No** (state-machine guarantee lost even if inserts succeed) |
| `cron` | `expire_stale_sessions`, `detect_offline_devices` | `private.expire_stale_sessions` (**unread**), `private.detect_offline_devices` (**unread**) | `remote_sessions`, `devices` | 2 functions | **No** |

**Consequence:** **8 of the 9 evidenced functions call at least one Postgres function that the artefact emits 0 of**, and
`remote-session` depends on a **trigger** that is likewise 0-of-7. So **9 of 9 cannot work correctly today, regardless of
deployment**, and this is true even on a hypothetically loaded structural-only schema. Independently, staging has **0
tables** and **0 Edge Functions**, so nothing works there at all today.

Two further dependency facts that constrain the brief's set:

* **`register-token` / `send-push` have no column.** Among all 183 captured columns the only `token`-shaped column is
  `pairing_requests.token_id` (local parse of `g1-q8-20261029.json`; `devices` has 25 columns, none push-related).
  `[02-architecture.md:104](../stage1/02-architecture.md)` and `SETUP-CHECKLIST.md:99` both state this. A push-token path
  therefore requires **DDL**, i.e. the A3-gated schema lane, not the A8 deploy lane.
* **No queue table exists** for `notification-queue` / `process-queue` (`91-coverage.md`:10 lists the 19 tables; no
  queue/outbox entry; [03-data-model.md:47](../stage1/03-data-model.md) `deletion_jobs` **MISSING**).

---

## 4. Function-to-service responsibility matrix

The owner's split is taken as given: **Firebase = Auth + Cloud Messaging; Supabase = all database work, server-side
business logic, SQL functions, Edge Functions, scheduled jobs, anything that must not trust the client.** This table
allocates *capabilities*, then flags overlaps. "Repo position" records what the repository currently says, which in two
rows **conflicts** with the split (§9 findings F-11, A4-F01).

| Capability | Per the owner's split | Repo's recorded position | Evidenced today | Overlap / duplicate responsibility flagged |
| --- | --- | --- | --- | --- |
| User authentication, sign-in, credential issuance | **Firebase-native** | [02-architecture.md:200](../stage1/02-architecture.md) row 1: "**Supabase Auth … the single identity authority**"; `:205` row 6 "Firebase Auth — **Not in the approved architecture.** Stays disabled"; `firebase/SETUP-CHECKLIST.md:16` D4 "Firebase Auth: **Leave disabled** — Supabase Auth is the single identity authority (architecture rule)" | `db.auth.getUser(token)` inside `_shared/auth.ts` for 7 of 9 functions (E4 `:61-72`) | **Direct conflict, not an overlap.** All 9 evidenced functions authorise against **Supabase** JWTs. A Firebase-ID-token model changes the auth primitive of every protected function |
| ID-token validation on protected functions | Supabase (must not trust the client) | Same Supabase path | No Firebase-token path evidenced (§5) | `verify-firebase-token` **overlaps** the in-handler `requireUser` already inlined in 8 bundles. Either it is a redundant second path, or `requireUser` must be re-plumbed. Evidence cannot choose |
| Role / family membership / consent authorisation | **Supabase** | Evidenced in-handler (E4 §4–§5) + partially in `private.*` | Yes (source-reviewed, never invoked) | Duplicated between handler assertions and `private.is_family_parent` / `is_family_member` / `shares_active_family` (E8 catalogue, `authenticated=X`, bodies read). Today the handlers use the service-role client and **never** call the policy-visible helpers; RLS is bypassed (E4 `:245`) |
| Transactional state (pairing, devices, policy, commands, sessions, alerts) | **Supabase** | Supabase Postgres, `SECURITY DEFINER` RPCs | Catalogued, **0 emitted** | None |
| Audit trail | **Supabase** | `_shared/audit.ts` inserts `audit_logs` directly; `private.record_audit` exists in the catalogue with `service_role=X` and an **unread** body | Both sides partly evidenced | **Duplicate write path.** No evidence names a caller of `private.record_audit`. Audit actor is **application-supplied**, not DB-derived (finding E14) |
| Push delivery to child devices | **Firebase-native (Cloud Messaging)** | Best-effort transport only; "never authoritative state" ([02-architecture.md:24](../stage1/02-architecture.md), `:84`); "FCM configured" = "**DOES NOT EXIST**" ([02-architecture.md:174](../stage1/02-architecture.md)) ⇒ `NOT STARTED` | **Nothing.** No project apps, no credentials, no FCM config (`E12` §2; [02-architecture.md:208-213](../stage1/02-architecture.md)) | **`send-push` vs FCM-direct overlap.** Repo rule "**no Firebase Admin SDK in any client**" ([02-architecture.md:140](../stage1/02-architecture.md)) forbids a client-direct privileged send. A data-message send from an app is not equivalent to a server send; if `send-push` exists *and* clients call FCM directly, two owners of one responsibility |
| Push-token registration | Supabase storage; Firebase issues the token | Design-only steps 3–5 ([02-architecture.md:102-104](../stage1/02-architecture.md)) | No column, no table, no function | **Overlap with `device-register`.** `register-token` and `device-register` would both write device-scoped credentials to `devices`; the repo has one evidenced registration path |
| Command queue / retry / ack | **Supabase** | `device_commands` + `poll_device_commands` + `ack` + `expire_stale_commands` | Catalogued, 0 emitted | **Two queue-processor names (`notification-queue`, `process-queue`) against one evidenced queue (`device_commands`) and zero queue tables.** Adding functions does not add a queue; a queue worker with no queue table is a no-op |
| Scheduled jobs | **Supabase** | `cron` with `x-cron-secret` | Deployed-in-prod at capture; caller/scheduler `NOT VERIFIED` (§6) | **Three cron-like names (`notification-cron`, `process-scheduled`, evidenced `cron`) for one evidenced scheduler-less function.** Duplicate scheduled work over `expire_stale_sessions` / `detect_offline_devices` would double-fire maintenance RPCs |
| Email / WhatsApp notifications | Firebase-native *or* third-party; **not** database work | Zero evidence in any form | Nothing | New capability. Must not be justified by repository precedent, because none exists |
| Live row updates | **Supabase Realtime** | 4 tables, `postgres_changes` (E7 `:171`); publication 0-of-4 emitted | `INFERRED FROM DOCUMENTATION` | **Overlapping notification lanes:** Realtime (row image, RLS-authorised) and FCM (hint). Repo rule: "state is written first, push is a hint. Never push-then-write" ([02-architecture.md:153](../stage1/02-architecture.md)). A notification pipeline that becomes authoritative breaks that invariant |
| Secrets / credentials custody | Supabase Edge secrets for anything server-side | `FCM_SERVICE_ACCOUNT_JSON` "S only"; "never in a client bundle" ([06-secrets-and-environments.md:20](../stage1/06-secrets-and-environments.md), `:36`) | **`NOT CREATED`** for staging ([01-staging-project-proposal.md:254](01-staging-project-proposal.md)); production values never read ([13:191](../stage1/13-edge-function-source-inventory.md)) | Two-console / two-identity boundary (§5, F-05) |

---

## 5. `verify-firebase-token` — forensic review

### 5.1 What the evidence shows

| Question | Evidence | Status |
| --- | --- | --- |
| Does a function with this slug exist? | 0 occurrences repo-wide (§2). The only Edge Function inventory (E1 `functions[0..8]`) names 9 slugs, none of which is it. `01-baseline-inventory.md:63-65`, `00-status-register.md:35`, [S2-EXEC-05-complete-stage1-evidence-inventory.md](S2-EXEC-05-complete-stage1-evidence-inventory.md):155-157 each enumerate the same 9 | **`NOT APPLICABLE` to the evidenced set.** Existence: `MISSING — SOURCE EVIDENCE ABSENT` |
| Is it deployed in production? | The capture enumerated "all 9 functions" (E1 `:9`) and reported "Edge function cannot be found" for staging (E12 `:91`). A 10th slug was never enumerated | **Cannot be answered today.** Re-observation would be a production read, prohibited (C2b/R-43; A1 `INOPERATIVE`) |
| What does the evidenced identity boundary actually do? | `_shared/auth.ts` `requireUser` = bearer extraction `/^Bearer\s+(\S+)$/i`, min length 20, then **`db.auth.getUser(token)`** — "Signature, expiry and revocation are decided by the Auth server, not by local decoding. A network failure is converted to `401 unauthorized`, so the path **fails closed**" (E4 `:62-64`; E1 `:166`) | **Verified** (read in deployed editor text, never invoked) |
| Which issuer does it validate? | Supabase Auth — `[02-architecture.md:200](../stage1/02-architecture.md)`: "It issues the user JWT every Edge Function call carries" | **Verified** |
| Any Firebase-ID-token artefact anywhere? | Searched for `verify-firebase-token`, `verifyIdToken`, `custom claims`, `Admin SDK` server use, `securetoken.googleapis.com`, `identitytoolkit`, `firebaseapp`, JWKS, `RS256`, `id_token` — **no hit** is a token-verification implementation. The only `Admin SDK` hits are *prohibitions* ([02-architecture.md:26](../stage1/02-architecture.md), `:140`) | **`MISSING — SOURCE EVIDENCE ABSENT`** |

### 5.2 Can a Deno Edge Function verify a Firebase ID token without a service-account key?

**This section is platform reasoning, not repository evidence.** The repository is silent; nothing below was observed in
this codebase, and it is labelled as analysis so it cannot be mistaken for a finding.

* **Signature + standard claims path — no key required.** A Firebase ID token is an RS256 JWT issued under
  `https://securetoken.googleapis.com/<project_id>` with `aud` = the Firebase project id. Verifying it needs only Google's
  **public JWKS**, fetched at runtime, plus issuer/audience/expiry checks. In Deno this is doable with `Web Crypto`
  (`crypto.subtle`) or a vendored JWT library; **no service-account key is involved**, and no Google Cloud credential is
  needed to *read* claims.
* **Custom claims — present in the payload.** Firebase custom claims ride **inside** the ID token, so a function that has
  verified the signature can read `role`, `family_id`, etc. without any key. **But** claims only exist if something
  *minted* them, and **setting** custom claims requires the Admin SDK / Identity Platform API with privileged credentials.
  The repository contains **no evidence of anything that would mint claims**, because Firebase Auth is recorded as
  disabled (`[02-architecture.md:205](../stage1/02-architecture.md)`, `:173`).
* **What genuinely needs privileged credentials:** revocation / "tokens valid after" enforcement, `get_user` round-trips,
  setting claims, and sending FCM. Those paths need either a **service-account JSON** (private key → OAuth2 access token)
  or Workload Identity Federation / an equivalent keyless credential.
* **Consequence for design:** a `verify-firebase-token` function is *technically* implementable key-free if (a) only
  signature + iss/aud/exp + in-payload claims are needed, and (b) a claim-minting path exists elsewhere. If revocation
  must be enforced — the property a parental-control product actually needs, since a revoked guardian must lose access
  immediately — then **either** the key lives in the Edge Function secret, **or** the check moves to Supabase-side
  `service_role` code, **or** the client-facing surface must not be the trust boundary. The repository offers no evidence
  to choose. **`MISSING — SOURCE EVIDENCE ABSENT`.**
* **Second consequence, evidenced:** the Admin-SDK-in-client prohibition is a *recorded rule*, not a preference
  ([02-architecture.md:140](../stage1/02-architecture.md): "If a device could send, any device could impersonate the
  server"). Any "Firebase Auth on the client, Supabase trusts the client" shortcut violates it and the tasking's own
  constraint.

### 5.3 Where would the key live

| Placement | Evidenced rule | Cite | Gate |
| --- | --- | --- | --- |
| Supabase Edge Function secret, set out-of-band, never in the repo | "Firebase Admin service-account JSON — **S only** (future FCM)"; never repo/APK/`config.toml`/chat/logs | [06-secrets-and-environments.md:20](../stage1/06-secrets-and-environments.md) | **A9** (set/rotate any secret) |
| Read via `Deno.env.get`, never logged | "read in code via `Deno.env.get` and never logged"; "no `console.log` of an env value" | [06-secrets-and-environments.md:36](../stage1/06-secrets-and-environments.md), `:44` | A9 / A8 |
| Gitignored | `service-account*.json`, `*-firebase-adminsdk-*.json` blocked by `.gitignore` lines 9-10 — **present in the repo's ignore rules** | [06-secrets-and-environments.md:40](../stage1/06-secrets-and-environments.md); [reports/stage1-final.md:227](../stage1/reports/stage1-final.md) | `NOT APPLICABLE` (prevention, not approval) |
| `.env.example` placeholder only | `# FCM_SERVICE_ACCOUNT_JSON=` is commented out | local read of `.env.example` | `NOT APPLICABLE` |
| Must **not** cross the two-console boundary | The Supabase owner and the Firebase owner are **different Google identities** (two operator identifiers, cited by line only: `S2-INSP-02:42-46`); "Any future work that links the two … crosses that boundary and needs an explicit owner decision"; "No credential crosses" | `docs/stage2/evidence/S2-INSP-02-firebase-console.md:42-50`; [04-risks-rollback-approvals.md](04-risks-rollback-approvals.md):387; `S2-REVIEW-03:344` row 5 | **A12** (unsigned) |

**Status: `BLOCKED — APPROVAL REQUIRED`.** The Firebase shell exists with **zero registered apps and zero credentials**
([approval-package-v2](approval-package-v2-ratification-and-forward.md):62, `:131`; `E12:192`), and A12's amended clause keeps
"app registration, FCM configuration, credentials and settings changes **prohibited**"
([04](04-risks-rollback-approvals.md):220). There is therefore **no credential to place, today, lawfully.**

### 5.4 Is the current implementation correct?

**Unanswerable, and the burden of proof has not been met by anything in this repository.** There is no `verify-firebase-token`
source, no digest, no char count, no anchor, no action list, no test case (E5 has no Firebase case), and no env var named
for it. The nearest evidenced token-validation code (`requireUser`) validates a **different issuer** and is inside a
module whose **full text is not in the repository** (E3 `:24`, `:141-147`).

**A4-F03 (finding, stated as required):** *do not assume the existing implementation is correct.* The evidence proves
neither correctness nor incorrectness. Any statement that `verify-firebase-token` "already handles" Firebase ID tokens,
or that it "can be reused", or that it "fails closed", is **unsupported by this repository** and must not be relied upon
by any plan, patch, or approval request.

### 5.5 What remains unverifiable from the repository

1. Whether the slug exists at all, in production or staging.
2. Its source text, size, digest, or action vocabulary.
3. Whether it uses a JWKS/custom-claims path or the Firebase Admin SDK.
4. Whether any service-account key is set as an Edge secret in production — the programme has never read production
   secrets by design ([13-edge-function-source-inventory.md:150-153](../stage1/13-edge-function-source-inventory.md), `:191` I4).
5. Whether any other function calls it, or whether it is dead code.
6. Whether it enforces revocation, `aud`, `iss`, or expiry.
7. Whether it fails closed on a network error (the evidenced Supabase path does; that says nothing about a Firebase path).
8. Whether the product even has a Firebase project for **production** — recorded as **not** existing
   ([02-architecture.md:225-226](../stage1/02-architecture.md)).

---

## 6. Cron / scheduled-job readiness

### 6.1 Evidenced state

| Item | Evidence | Status |
| --- | --- | --- |
| An evidenced scheduled **worker** exists | `cron`, actions `expire_sessions` → `rpc expire_stale_sessions()`, `detect_offline` → `rpc detect_offline_devices()` (E1 `:155`, `:160`) | `VERIFIED` (source read 2026-10-30, never invoked) |
| Its authentication | `x-cron-secret` header; `CRON_SECRET` <16 chars ⇒ `503 cron_not_configured`; SHA-256 + constant-time compare; missing/mismatch ⇒ `401` (E1 `:156`, `:159`; E4 `:319-322`). E4 `:404` records this check verbatim as "**NOT TESTED**" at runtime | `VERIFIED` (static source read 2026-10-30 only; never invoked or tested, per E4 `:404`) |
| **What invokes it** | "**NOT VERIFIED**"; "what invokes it, and whether `pg_cron` exists, is **NOT VERIFIED**"; "What invokes `cron`, on what schedule, and is `pg_cron` installed? **Neither is recorded in Stage 1**" | `MISSING — SOURCE EVIDENCE ABSENT` — [01-staging-project-proposal.md:70](01-staging-project-proposal.md), `:284`; `parts/A-staging-spec.md:52`, `:198`; [07-ops-and-observability.md:49](../stage1/07-ops-and-observability.md) |
| Whether a **schedule** is configured anywhere | "whether `cron` performs any retention or purge is unknown … **NOT VERIFIED**"; "Add an IP allowlist if the **scheduler's** egress ranges are known" (E6 `:460-461` — the scheduler is treated as unknown) | `MISSING — SOURCE EVIDENCE ABSENT` |
| `pg_cron` / extensions | Extensions **`NOT PRESENT IN EVIDENCE`, expected count UNKNOWN, not zero**; "Do not infer `pgcrypto`, `uuid-ossp` or **`pg_cron`**" | `MISSING — SOURCE EVIDENCE ABSENT` — `g3-build/90-limitations.md`:62; `parts/A-staging-spec.md:49` |
| Whether a *notification* cron exists | 0 occurrences of `notification-cron` (§2) | `MISSING — SOURCE EVIDENCE ABSENT` |
| Whether `process-scheduled` exists | 0 occurrences (§2) | `MISSING — SOURCE EVIDENCE ABSENT` |

### 6.2 What Supabase Dashboard scheduling requires — and what this repository can say about it

**Honest answer: the repository contains no observation of a Supabase scheduling UI, no cron-definition artefact, and no
statement of what such a configuration requires.** Recording the platform's general shape here would be inventing
evidence. Two things *are* evidenced and are sufficient to answer the readiness question:

1. **The programme's staging spec deliberately excludes a scheduler.** "Cron scheduler | Function `cron` + `CRON_SECRET`;
   caller **NOT VERIFIED** → **Function only, no scheduler** | D — a scheduler in staging could generate traffic nobody is
   watching" ([01-staging-project-proposal.md:70](01-staging-project-proposal.md); repeated `:77`,
   `parts/A-staging-spec.md:185`, and `evidence/S2-NEXT-01-readiness-report.md:188` "Create a cron job or scheduler in
   staging — **none (deliberate deviation)**"). The deviation itself is **`NOT APPROVED`** — the checklist box
   "Deviations approved: … no cron scheduler …" is an unticked item (`parts/A-staging-spec.md:185`).
2. **The functions page has never been written to.** `Deploy a new function` was visible and **not clicked** (`E12:224`),
   and no scheduling control is named anywhere in any capture (§5 of `E12` lists the tooling limits; §6 lists clicked vs
   un-clicked controls — a scheduler is not among them either way).

### 6.3 Gate-blocked? Yes — and by four gates, not one

| Gate | Why it is on the cron path | Status |
| --- | --- | --- |
| **A7** | Export the source before any deploy; A7 **forbids "deploying from a minified bundle"** ([04](04-risks-rollback-approvals.md):215) and `cron` is one of the 7 minified bundles (E1 `:151`) | `BLOCKED — APPROVAL REQUIRED` |
| **A3** | Both cron actions are `private.*` RPCs the artefact emits **0 of** (§3.2); the schedule has nothing to call | `BLOCKED — APPROVAL REQUIRED` (unsigned) |
| **A9** | `CRON_SECRET` must be created for staging; staging secrets are **`NOT CREATED`** ([01-staging-project-proposal.md:254](01-staging-project-proposal.md)) | `BLOCKED — APPROVAL REQUIRED` (unsigned) |
| **A8** | Deploy the function ([04](04-risks-rollback-approvals.md):216) | `BLOCKED — APPROVAL REQUIRED` |
| (A2′ deviation) | Accepting "no scheduler" in staging | `BLOCKED — APPROVAL REQUIRED` (checklist unticked) |

### 6.4 Evidence needed to call scheduling `CONFIGURED`

None of the following exists in the repository; all would have to be produced from an authorised, dated, staging-ref-only
observation, recorded in UTC:

1. A named schedule object bound to a named slug, with its cron expression/timezone/enabled state and the project ref in
   the console header echoed alongside it (per C2b/R-43's ref-echo rule).
2. The secret-name row (`CRON_SECRET`) present in the project's secrets list, **by name and digest only** (A9's evidence
   field, [04](04-risks-rollback-approvals.md):217).
3. At least one **observed invocation** — a log line or an effect on `remote_sessions.status` / `devices.last_seen_at`
   attributable to the scheduler rather than to a manual call.
4. A statement of which of the two schemes the caller uses (static `x-cron-secret` header vs the HMAC/nonce remediation
   proposed at E6 `:449-461`), because E12's replay weakness is only closed if caller and function change together
   ("The scheduler must change in the same window as the function; a mismatch stops all maintenance", E6 `:463`).
5. Whether `pg_cron` is installed — currently `UNKNOWN` and un-answerable without an extension read that no gate permits.

**Verdict: `NOT STARTED` for `notification-cron` and `process-scheduled` (no evidence they exist); `BLOCKED — APPROVAL
REQUIRED` for `cron` scheduling.**

---

## 7. Secrets and environment-variable register

**Names only, never values.** Where the repository states a presence/absence fact, it is quoted with its line; the Status
column maps to the sanctioned vocabulary.

| Name (no value) | Evidenced where it is read | Consumer functions (evidenced) | Recorded state (verbatim + cite) → **mapped Status** | Governing approval gate |
| --- | --- | --- | --- | --- |
| `SUPABASE_URL` | [13-edge-function-source-inventory.md:150](../stage1/13-edge-function-source-inventory.md); [04-rls-matrix.md:195](../stage1/04-rls-matrix.md) "every one of the nine creates its client with `SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY`" | all 9 | prod: "`NOT VERIFIED`" (values never read, [13:152](../stage1/13-edge-function-source-inventory.md)); staging: "`NOT CREATED`" ([01](01-staging-project-proposal.md):254) ⇒ **`BLOCKED — APPROVAL REQUIRED`** | **A9** |
| `SUPABASE_SERVICE_ROLE_KEY` | same; "read from `Deno.env` at first use and cached; a missing value throws `503 server_misconfigured`" (E4 `:248-249`) | all 9 | as row above ⇒ **`BLOCKED — APPROVAL REQUIRED`** | **A9**; repo forbids it in repo/`.env.example`/`config.toml`/APK/CI logs ([06](../stage1/06-secrets-and-environments.md):16) |
| `SUPABASE_ANON_KEY` | gateway `apikey` on every call (E5 `:30-31`); `.env.example` present with empty value | client-side; not read by any function per evidence | staging: "`NOT CREATED`" ([01](01-staging-project-proposal.md):254) ⇒ **`BLOCKED — APPROVAL REQUIRED`** | **A9** |
| `CRON_SECRET` | E1 `functions[8].anchors.auth` `:156`, `:159`; [13](../stage1/13-edge-function-source-inventory.md):151; `parts/A-staging-spec.md:52` | `cron` | prod: "Whether … `CRON_SECRET` [is] actually set is **NOT VERIFIED**; the code's behaviour when they are not set is **VERIFIED**" ([13:152](../stage1/13-edge-function-source-inventory.md)); staging: "`NOT CREATED`" ⇒ **`BLOCKED — APPROVAL REQUIRED`** | **A9** |
| `PAIRING_HASH_PEPPER` | [13:151](../stage1/13-edge-function-source-inventory.md); E1 `shared[5].note` `:170`; `parts/F-e6-e7.md:23` `Deno.env.get("PAIRING_HASH_PEPPER") ?? ""` | `pairing` (via `_shared/validation.ts`) | prod presence "**NOT VERIFIED**", still an open owner question — "Is `PAIRING_HASH_PEPPER` present in production? (Presence only — never the value)" ([04](04-risks-rollback-approvals.md):405; U-13 [approval-package-v2](approval-package-v2-ratification-and-forward.md):438); staging "`NOT CREATED`"; silent SHA-256 fallback = finding E6 ⇒ **`BLOCKED — APPROVAL REQUIRED`** | **A9**; **rotation of the production pepper is forbidden in Stage 2** ([04](04-risks-rollback-approvals.md):217, R-07) |
| `TURN_SECRET` | E1 `functions[7].anchors.ice` `:146` | `remote-session` | prod values "never read" ([13:191](../stage1/13-edge-function-source-inventory.md) I4); staging "separate credentials **or unset**" (`parts/A-staging-spec.md:53`) ⇒ **`BLOCKED — APPROVAL REQUIRED`** | **A9** |
| `TURN_URL` / `STUN_URL` | [13:151](../stage1/13-edge-function-source-inventory.md); `parts/A-staging-spec.md:53` | `remote-session` (inferred from provider naming — **which** function reads them is `INFERRED`, not evidenced per-slug) | "values/provider not read" (`parts/A-staging-spec.md:53`) ⇒ **`BLOCKED — APPROVAL REQUIRED`** | **A9** |
| `FCM_SERVICE_ACCOUNT_JSON` | `.env.example` (commented); [06](../stage1/06-secrets-and-environments.md):20, `:36`, `:77` "`(none yet)`"; `SETUP-CHECKLIST.md:88` | **no consumer function exists** (§2) | "**(none yet)**" ([06](../stage1/06-secrets-and-environments.md):77); zero credentials on the Firebase shell ([approval-package-v2](approval-package-v2-ratification-and-forward.md):62) ⇒ **`NOT STARTED`** | **A9** (Supabase side) **+ A12** (Firebase side, `UNSIGNED` as a forward block) |
| `FIREBASE_PROJECT_ID`, `FIREBASE_APP_ID_ANDROID` | `.env.example` (empty); [06](../stage1/06-secrets-and-environments.md):19 "the non-secret project id" | none evidenced | "no Firebase app registered for this product" ([02-architecture.md:208-213](../stage1/02-architecture.md)) ⇒ **`NOT STARTED`** | **A12** |
| Legacy FCM server key (`AAAA…` shape) | [06](../stage1/06-secrets-and-environments.md):21 — "only if a legacy sender is unavoidable"; `SETUP-CHECKLIST.md:83` "**Do not enable the legacy server key**" | none | explicitly not to be created ⇒ **`NOT APPLICABLE`** | **A9**/**A12** if ever revisited |
| `SUPABASE_DB_PASSWORD`, `SUPABASE_ACCESS_TOKEN` | [06](../stage1/06-secrets-and-environments.md):17-18 | operator-side, **not** a function env var | custody "**NOT VERIFIED**" (R-39 [04](04-risks-rollback-approvals.md):97) ⇒ **`BLOCKED — APPROVAL REQUIRED`** to use; rotation is an A9 action | **A9** |
| "JWT signing secret" | [approval-package-v2](approval-package-v2-ratification-and-forward.md):331 (A9 authorises creating fresh staging values incl. "JWT signing secret") | not referenced by any evidenced function | "`NOT CREATED`" ([01](01-staging-project-proposal.md):254) ⇒ **`BLOCKED — APPROVAL REQUIRED`** | **A9** |
| Env vars for the brief's nine functions | **no name is evidenced** | — | **`MISSING — SOURCE EVIDENCE ABSENT`** | cannot be assigned |

**Register-level statements.** (a) No secret value was read, listed, created or rotated by this audit; (b) production
secrets have **never** been read by this programme, by design ([13:152](../stage1/13-edge-function-source-inventory.md));
(c) staging has **no secrets at all** — "`BLOCKED — STAGING FUNCTIONS NOT DEPLOYED` … staging secrets do not exist (A9
unsigned, R-39)" ([S2-EXEC-04-a3-precondition-matrix.md](S2-EXEC-04-a3-precondition-matrix.md):134; [01](01-staging-project-proposal.md):254
`NOT CREATED`); (d) A9's evidence field is **name + digest only** ([04](04-risks-rollback-approvals.md):217).

---

## 8. Deployment readiness report

### 8.1 The browser-only path, stated from evidence

* **Constraint C1 is binding:** "Supabase **web dashboard only**; no Supabase CLI, no Firebase CLI, no terminal
  migrations, no direct production API calls … every SQL step is a pasted, reviewed block in the dashboard SQL Editor"
  ([00-stage2-execution-plan.md:39](00-stage2-execution-plan.md)). G3's `supabase db dump` route died on exactly this
  (R-14 [04](04-risks-rollback-approvals.md):72; A0 amendment [04](04-risks-rollback-approvals.md):209).
* **Observed staging surface:** `.../project/dzonzgngwxclhfnvxtvu/functions` rendered "Edge function cannot be found in
  your project" (`E12:88-91`), and the control **`Deploy a new function`** was visible and **not clicked** (`E12:224`).
  That is the *whole* evidenced dashboard surface for deploys.
* **Observed production surface (historical):** the code view `/dashboard/project/<ref>/functions/<slug>/code` and the
  per-function **Download → Download as ZIP** affordance (E1 `:9-10`; [13:177-179](../stage1/13-edge-function-source-inventory.md)).
  **Production is not openable** — C2b/R-43 absolute, A1 `INOPERATIVE`.
* **Not evidenced, and therefore not claimed by this report:** which dashboard page holds the deploy form, whether the
  browser path supports multi-file functions with `_shared/` imports, whether an import map can be supplied, how secrets
  attach to a deployed function in-browser, or whether in-browser editing is even offered for a 9-module project. **All
  `MISSING — SOURCE EVIDENCE ABSENT`.** This is a material gap, not a detail: the only evidenced repository facts about
  deploy tooling are that `supabase/functions/` is **absent** and `import_map_or_deno_json` is **absent** (E1
  `repository` `:172-176`), while every evidenced function imports six `_shared/*.ts` modules (E1 `imports` `:33`).
* **A7 forbids the shortcut.** The approval row for exporting Edge source explicitly lists as *Forbidden*: "Editing live
  functions in the dashboard; **deploying from a minified bundle**" ([04](04-risks-rollback-approvals.md):215). Seven of the
  nine evidenced functions **are** minified bundles (E1 `form`, `lines: 2`). A browser-pasted redeploy of a captured
  bundle is therefore prohibited by the gate that would govern it.
* **The CLI procedure that *would* work is out of bounds:** [13:157-182](../stage1/13-edge-function-source-inventory.md) §7
  (`supabase functions download …`) is recorded as `PROPOSED — NOT APPLIED` and requires an owner credential and a linked
  project; C1 excludes it.

### 8.2 Per-function readiness

Common precondition chain, all four of which are unsatisfied: **A7** (source export) → **A3** (schema load, unsigned,
`NOT LOAD-READY`) → **A9** (secrets, unsigned) → **A8** (deploy, no signature recorded).

| Function | Deployment readiness | Blocking reason (cited) |
| --- | --- | --- |
| `pairing` | **`BLOCKED — APPROVAL REQUIRED`** | 7-module import tree + `supabase/functions/` absent (E1 `:33`, `:174`); E6/E7 handler fixes `BLOCKED — EDGE SOURCE REQUIRED` ([00](00-stage2-execution-plan.md):118-120; [02-findings-to-fix-mapping.md](02-findings-to-fix-mapping.md):33); 4 required RPCs 0-emitted; `PAIRING_HASH_PEPPER` unresolved |
| `auth-bootstrap` | **`BLOCKED — APPROVAL REQUIRED`** | required RPC 0-emitted; `profiles_before_update`/`families_before_update` triggers 0-emitted; auth-issuer conflict (§4, A4-F11) makes its `set_role`/`create_family` semantics undefined under Firebase Auth |
| `device-command` | **`BLOCKED — APPROVAL REQUIRED`** | 2 required RPCs 0-emitted; minified ⇒ A7-forbidden bundle deploy |
| `device-register` | **`BLOCKED — APPROVAL REQUIRED`** | no RPC dependency, but A7/A3/A9/A8 chain plus E10 (client-chosen secret) unresolved |
| `device-policy` | **`BLOCKED — APPROVAL REQUIRED`** | 1 required RPC 0-emitted; minified |
| `device-telemetry` | **`BLOCKED — APPROVAL REQUIRED`** | 1 required RPC 0-emitted; E13 no-audit-row defect open |
| `family-admin` | **`BLOCKED — APPROVAL REQUIRED`** | `private.revoke_device` body unread ⇒ handler authorisation `NOT VERIFIED` (E4 `:53-55`); E2/F8 grant patch (P01) `NOT EXECUTABLE` ([04](04-risks-rollback-approvals.md):213) |
| `remote-session` | **`BLOCKED — APPROVAL REQUIRED`** | `remote_sessions_transition_guard` trigger 0-emitted ⇒ deploying it **today** re-creates finding E4 with no DB backstop; P03 `BLOCKED — PRODUCTION READ NOT AUTHORISABLE`; `TURN_SECRET` `NOT CREATED` |
| `cron` | **`BLOCKED — APPROVAL REQUIRED`** | 2 required RPCs 0-emitted; `CRON_SECRET` `NOT CREATED`; scheduler deviation un-accepted (`parts/A-staging-spec.md:185`) |
| The brief's nine | **`NOT STARTED`** | No evidence of existence (§2). Not `PLANNED`, because `PLANNED` would require a named plan of record for each — there is none |

### 8.3 What cannot be deployed because the schema is `NOT LOAD-READY`

**All of it — 9 of 9 evidenced and 9 of 9 asserted.** Precisely:

* **8 of 9 evidenced functions** call `private.*`/`public.*` RPCs that the artefact emits **0 of 38** (`91-coverage.md`:14;
  `90-limitations.md`:34-45). Deploying them against a structural-only load produces a runtime undefined-function error,
  not a degraded success.
* **`remote-session`** additionally depends on a **0-of-7** trigger for its single-session invariant
  (`91-coverage.md`:18; [04](04-risks-rollback-approvals.md):27 R-05).
* **`device-register`** is the only evidenced function with no RPC call, so it is the *least* blocked — but its
  `updated_at` maintenance, `audit_logs` append-only protection and every RLS policy are 0-emitted, and staging has **0
  tables** until A3. Recorded as `BLOCKED — APPROVAL REQUIRED`, not as deployable.
* **Nothing of the brief's nine is deployable**, because 6 of them (`register-token`, `send-push`, `notification-queue`,
  `process-queue`, `process-scheduled`, `notification-cron`) additionally require **tables or columns that do not exist in
  any capture** and are not in the reconstruction either (§3, last two bullets).

### 8.4 Sequencing note the plan already makes

"Edge source: name who exports it; **until then steps 6 and G5-E cannot start**" (`parts/J`-referenced at
[06-redteam-resolution.md](06-redteam-resolution.md):112, D-11) and U-12 "Edge Function source: who exports it |
**OPEN / DEFERRED** — staging has 0 Edge Functions; nothing was exported"
([approval-package-v2](approval-package-v2-ratification-and-forward.md):437). G5-E's 108 HTTP cases remain
`BLOCKED — STAGING FUNCTIONS NOT DEPLOYED` ([05-validation-plan.md:25](05-validation-plan.md), `:120-132`).

---

## 9. Findings by severity

### CRITICAL

**A4-F01 — The brief's function inventory is unsupported by this repository, and is contradicted by it.**
All nine names — `notification-cron`, `notification-queue`, `process-queue`, `process-scheduled`, `register-token`,
`send-email`, `send-whatsapp`, `send-push`, `verify-firebase-token` — have **0 occurrences** in any tracked file (§2),
while the repository's only Edge Function inventory names a **disjoint** nine (`E1` `:26,44,58,73,86,99,115,132,150`;
[01-baseline-inventory.md:63-65](../stage1/01-baseline-inventory.md); [00-status-register.md:35](../stage1/00-status-register.md)) and
independently states "**No Edge Function currently sends FCM**" (`firebase/SETUP-CHECKLIST.md:100`). Any plan, estimate or
approval built on the brief's list is built on an unverified premise. This is exactly the failure mode
[S2-REVIEW-03-independent-audit.md:354](S2-REVIEW-03-independent-audit.md) warns about: "that belief must be corrected
before any Firebase work is scheduled."

**A4-F02 — Nothing in the Edge lane can work, deploy or be tested today, and the blocker is the schema, not the deploy.**
0 Edge Functions in staging (`E12:88-91`, `:192`); 0 tables (`E12:192`); artefact `NOT LOAD-READY` with **0 of 38 functions,
0 of 7 triggers, 0 of 21 policies** (`90-limitations.md`:14-22); A3 unsigned
([S2-EXEC-04-a3-precondition-matrix.md](S2-EXEC-04-a3-precondition-matrix.md):38)); 8 of 9 evidenced functions call RPCs in
that 0 set (§3.2); G5-E is `BLOCKED — STAGING FUNCTIONS NOT DEPLOYED` ([05-validation-plan.md:25](05-validation-plan.md)).

### HIGH

**A4-F03 — `verify-firebase-token`: correctness is unprovable here.** No source, digest, env var, action vocabulary or
test case exists (§5.4). **Do not assume the existing implementation is correct** — the evidence proves neither
correctness nor incorrectness, and that asymmetry is itself the finding.

**A4-F04 — The evidenced auth primitive is Supabase, not Firebase, and its real code is not in the repository.**
`requireUser` = `db.auth.getUser(token)` (E4 `:62-64`; `E1 shared[1].note` `:166`), applied across all 9 handlers, every one
of which runs as **`service_role` so "RLS never applies"** (E4 `:245`). Re-pointing to Firebase ID tokens is not a config
change; it touches an auth primitive whose **full source is absent** ([13:24](../stage1/13-edge-function-source-inventory.md),
`:141-147`). The `pairing/` evidence directory that would hold it is **empty** (`E2`;
[S2-EXEC-05-complete-stage1-evidence-inventory.md](S2-EXEC-05-complete-stage1-evidence-inventory.md):36, `:335`).

**A4-F05 — The Firebase service-account credential cannot lawfully exist yet, and its crossing is unowned.**
The Firebase shell has **zero apps, zero credentials, no FCM configuration**
([approval-package-v2](approval-package-v2-ratification-and-forward.md):62); A12 is **unsigned as a forward block** with
credentials explicitly still prohibited ([04](04-risks-rollback-approvals.md):220); the Supabase and Firebase consoles are
**different Google identities** (identifier strings cited at `S2-INSP-02:42-50`, not reproduced), and "no credential
crosses" is a standing statement ([04](04-risks-rollback-approvals.md):387). So the key that a Firebase-auth architecture
depends on has **no approved home and no approved owner**.

**A4-F06 — The push path has no data model: no token column, no token table, among 183 captured columns.**
Local parse of `g1-q8-20261029.json`: `devices` = 25 columns, none push-related; the only `*token*` column in the whole
schema is `pairing_requests.token_id`. Corroborated by `SETUP-CHECKLIST.md:99` and
[02-architecture.md:104](../stage1/02-architecture.md) / `:175` (`PROPOSED`). Therefore `register-token` and `send-push`
require **DDL** in the A3 lane, not an A8 deploy — a scope the brief does not acknowledge.

**A4-F07 — A7 prohibits the only deployable artefact this programme holds.** A7's Forbidden column: "deploying from a
minified bundle" ([04](04-risks-rollback-approvals.md):215), and **7 of 9** evidenced functions are 2-line minified bundles
(E1 `form`/`lines`; [13:141-147](../stage1/13-edge-function-source-inventory.md)). The browser-only constraint (C1) removes the
CLI export route ([13:157-182](../stage1/13-edge-function-source-inventory.md) `PROPOSED — NOT APPLIED`). Net: **no
gate-compliant deploy path exists in-browser for those seven.**

### MEDIUM

**A4-F08 — Duplicate/overlapping responsibilities in the proposed set.** Two queue processors against zero queue tables
(`91-coverage.md`:10; [03-data-model.md:47](../stage1/03-data-model.md) `deletion_jobs` MISSING) and one evidenced queue
(`device_commands` poll/ack); three cron-like names against one evidenced scheduler-less `cron`; `send-push` against the
recorded rule "no Firebase Admin SDK in any client" ([02-architecture.md:140](../stage1/02-architecture.md));
`register-token` against `device-register` (both would write device-scoped credentials); `verify-firebase-token` against
the inlined `requireUser`. See §4.

**A4-F09 — Scheduled work has no evidenced caller.** What invokes `cron`, on what schedule, and whether `pg_cron` exists:
**all `NOT VERIFIED`** ([01](01-staging-project-proposal.md):70, `:284`; `parts/A-staging-spec.md:52`, `:198`;
[07-ops-and-observability.md:49](../stage1/07-ops-and-observability.md)); extensions count **UNKNOWN, "not zero"**
(`90-limitations.md`:62). Consequence already risk-registered: R-05, "expired rows keep a live status until `cron
expire_sessions` runs; **scheduler reliability is NOT VERIFIED**" ([04](04-risks-rollback-approvals.md):27).

**A4-F10 — E6 and E7 are handler fixes that no SQL patch can substitute.** "A database-side rate-limit table has no writer
if the handler is not deployed to increment it, which would let the plan record 'E7 mitigated' while nothing is mitigated.
Both are marked `BLOCKED — EDGE SOURCE REQUIRED`" ([00](00-stage2-execution-plan.md):118-120;
[02-findings-to-fix-mapping.md](02-findings-to-fix-mapping.md):33; [06-redteam-resolution.md](06-redteam-resolution.md) J-11). Any new
notification function inherits the same no-rate-limit posture (finding E7, "VERIFIED absent" across all bundles,
E4 `:234-237`).

**A4-F11 — The owner's direction conflicts with recorded, unamended architecture decisions.** Firebase Auth is listed as
"**Not in the approved architecture. Stays disabled**" ([02-architecture.md:205](../stage1/02-architecture.md)), Supabase
Auth as "the single identity authority" (`:200`), and D4 "Firebase Auth — **Leave disabled**"
(`firebase/SETUP-CHECKLIST.md:16`) with the stated reason "Supabase Auth is the single identity authority (architecture
rule)". **A direction is not an amendment**: no gate is signed, `04` §6 is "RECORDED — NO ACTION AUTHORISED"
([04](04-risks-rollback-approvals.md):346), and [S2-REVIEW-03-independent-audit.md:64](S2-REVIEW-03-independent-audit.md) already
answered the earlier version of this premise ("The premise is false on its first half"). The conflict must be resolved by
the owner **in writing** before any auth-adjacent Edge work is scoped.

**A4-F12 — Two audit-write paths, one with no evidenced caller.** `_shared/audit.ts` inserts `audit_logs` directly with a
caller-supplied `actor_user_id` (E1 `:165`), while `private.record_audit(p_family_id, p_actor_user_id, p_device_id,
p_event_type, p_target_type, p_target_id, p_metadata)` exists in the catalogue with `service_role=X` and an **unread** body
(E8 `inventory`; [00-status-register.md](../stage1/00-status-register.md) PA3). Nothing names a caller. Overlap + unverified path.

### LOW

**A4-F13 — `docs/stage1/evidence/edge-functions/pairing/` is an empty directory** (0 entries; `sha256sum`/`ls` this pass),
although `E1 capture.operations_performed` `:10` describes reads of `pairing/code`, `auth-bootstrap/code` and "each
`_shared/*.ts` entry in the file tree". The shared-module captures survive only as six rows of `E1 shared[]`, not as
per-file artefacts. Confirmed independently at
[S2-EXEC-05-complete-stage1-evidence-inventory.md](S2-EXEC-05-complete-stage1-evidence-inventory.md):36, `:335`.

**A4-F14 — The whole Edge inventory is a frozen, single-surface historical snapshot.** It was captured from
**production** (`E1 capture` `:4-6`) on 2026-10-30; editor text ⇒ deployed bytes is **`INFERRED`, not proven**, and "a
deploy performed after capture would invalidate them silently; re-read before relying on them"
([13:134-137](../stage1/13-edge-function-source-inventory.md)). Re-reading is now prohibited (C2b/R-43, A1 `INOPERATIVE`), so the
digests in §2.1 can never be refreshed by this programme.

**A4-F15 — Local build artefacts do not describe the deployed runtime.** `supabase/functions/` absent and
`import_map_or_deno_json` absent (E1 `repository` `:172-176`), while `config.toml` declares `[api] schemas = [public,
graphql_public]` against a deployed `[public, extensions]` ⇒ "**the local file is not a description of production**"
(E1 `:175`; [13:27-31](../stage1/13-edge-function-source-inventory.md), I5). Nine functions × six `_shared` imports with **no
dependency-resolution artefact in evidence** is an unresolved deploy-design gap for a browser-only path.

**A4-F16 — Carried-forward handler defects that any new notification function will inherit.** E12 static replayable
`CRON_SECRET` (E6 `:447-461`); E13 telemetry writes no audit rows (`VERIFIED`, [13:110-112](../stage1/13-edge-function-source-inventory.md));
E14 audit actor is application-supplied; E9 wildcard CORS advertising `x-cron-secret`/`x-device-secret`
(E4 `:259-267`); `location_events` plain insert ⇒ retried uploads duplicate (E4 `:314-316`).

---

## 10. What this audit could not determine, and why

| # | Could not determine | Why |
| --- | --- | --- |
| 1 | Whether **any** of the brief's nine functions exists | No occurrence anywhere (§2); the only inventory names a disjoint set; confirming absence in production would be a **production read**, prohibited absolutely (C2b/R-43, A1 `INOPERATIVE`) |
| 2 | Whether production **currently** still runs the evidenced nine, or has changed since 2026-10-30 | Same prohibition. The inventory is historical ([04](04-risks-rollback-approvals.md):101); the drift re-verification obligation R-28 is **unsatisfiable** and no substitute is recorded ([S2-EXEC-04-a3-precondition-matrix.md](S2-EXEC-04-a3-precondition-matrix.md):66 M-18) |
| 3 | Whether editor text equals deployed bytes | "no source maps … **INFERRED**, not proven"; a ZIP attempt produced a transient file that disappeared ([13:134-149](../stage1/13-edge-function-source-inventory.md), `:177-179`) |
| 4 | The behaviour of 24 of 38 `private.*` implementations that the functions call | Bodies never captured (PA3, [00-status-register.md](../stage1/00-status-register.md)); `91-coverage.md`:16; cannot be recovered offline (L-1/L-2 = "No") |
| 5 | The **full** text of `_shared/auth.ts` / `validation.ts` | Char counts + digests + a summary note only; the `pairing/` directory is empty (`E2`); the editor "only exposes the entry file" (`E7:90`) |
| 6 | Whether `CRON_SECRET`, `PAIRING_HASH_PEPPER`, `TURN_SECRET` are set in production | Values and presence deliberately never read ([13:150-153](../stage1/13-edge-function-source-inventory.md), I4; U-13 [approval-package-v2](approval-package-v2-ratification-and-forward.md):438) |
| 7 | What invokes `cron`, on what schedule, and whether `pg_cron` / any extension exists | Never recorded; extensions `UNKNOWN` (`90-limitations.md`:62); no `pg_extension` row exists |
| 8 | Which dashboard page/form a browser-only deploy of a 9-module Deno function uses, and whether multi-file `_shared/` imports are supported at all | No capture has ever opened a deploy surface; `Deploy a new function` was seen and not clicked (`E12:224`). Naming it would be inventing evidence (§8.1) |
| 9 | Runtime behaviour of anything | "No request was made. Every runtime claim is source-derived" ([13:154-155](../stage1/13-edge-function-source-inventory.md)); E5 `NOT EXECUTED`; G5-E `BLOCKED — STAGING FUNCTIONS NOT DEPLOYED` |
| 10 | Whether `verify-firebase-token` uses a keyless JWKS path or the Admin SDK, and whether it fails closed | §5.5 — no source of any kind |
| 11 | Where a Firebase service-account key would be created, by whom, and whether the two identities will ever be linked | A12 unsigned; zero apps/credentials; identity boundary is an **owner decision outside Stage 2** ([04](04-risks-rollback-approvals.md):380, `:220`) |
| 12 | Whether staging is currently reachable/unpaused | The 2026-11-02T07:16Z read is **historical**; "as of the writing of this file the project's status is **UNKNOWN**" ([S2-EXEC-04-a3-precondition-matrix.md](S2-EXEC-04-a3-precondition-matrix.md):204), and the 2026-11-06 touch deadline has since passed with **no owned action** (`:209`, S4-BL-10) |
| 13 | Whether the 19 tables in the artefact are the tables the notification set would need | New capabilities (`email`, `whatsapp`, queue, token) have no modelled table; nothing in the evidence proposes one |
| 14 | Whether `private.expire_stale_commands` is called by anyone | Present in the catalogue (E8); no evidenced call site in E1 |

---

## 11. Split view

### Verified (read from a named file, this pass or cited from capture)

* The capture file is present, 14,118 bytes / 178 lines, and hashes to `95ebe57cf6d0aa06…` — **matching the digest
  independently recorded** at [S2-EXEC-05-complete-stage1-evidence-inventory.md](S2-EXEC-05-complete-stage1-evidence-inventory.md):46.
* Nine evidenced slugs with per-slug char counts, line counts and SHA-256 digests (E1 `:26-162`); six `_shared` modules with
  the same (E1 `:165-170`).
* `supabase/functions/` and `import_map_or_deno_json` are **absent** (E1 `repository` `:174`, `:176`; confirmed by local
  `ls`: `D:/control/supabase/` contains only `config.toml` and `.gitignore`).
* `edge-functions/pairing/` is an empty directory (local `ls`; `E2`).
* 0 repo-wide occurrences of each of the brief's nine names; 0 of `smtp`/`sendgrid`/`whatsapp`/`twilio`/`fcm`-as-function
  (local `grep`).
* `g1-b3b` = 38 Postgres functions / 14 bodies; `g1-q10` = 14 **public Postgres** functions; `g1-q9` = Security-Advisor
  lint (33 occurrence-rows) — **none is an Edge Function list** (local JSON parse; corroborated at
  [S2-EXEC-05-complete-stage1-evidence-inventory.md](S2-EXEC-05-complete-stage1-evidence-inventory.md):28).
* `devices` has 25 columns, none push/token-related; the sole `*token*` column in 183 is `pairing_requests.token_id`
  (local parse of `g1-q8-20261029.json`).
* Staging: 0 Edge Functions, 0 tables, `No migrations`, `No backups`, slots 2/2/0 — `VERIFIED (re-confirmed)` at
  `E12:192`, `:88-91`, `:37`.
* Artefact: 459 active statements; **0** function / trigger / policy / publication statements; `NOT LOAD-READY`.
* Gates: A2′/A3/A9/A12 unsigned; A0 approved-recorded, fence unfilled; A5 approved-not-executable; A1 `INOPERATIVE`
  ([04](04-risks-rollback-approvals.md):205, `:209`, `:212-213`, `:220`).
* A7 forbids "deploying from a minified bundle"; A8 is the deploy gate ([04](04-risks-rollback-approvals.md):215-216).

### Inferred (follows from evidence; not observed)

* The shared-module bodies inlined into each bundle behave identically to the readable copies — matched by behaviour,
  "that match is **INFERRED**, not byte-identical" ([13:144-147](../stage1/13-edge-function-source-inventory.md)).
* `TURN_URL`/`STUN_URL` are read by `remote-session` — inferred from the ICE-credential anchor (E1 `:146`) plus the env
  name list; no per-function env mapping exists in evidence.
* `device-register` would be the least schema-blocked evidenced function (no evidenced RPC), **but** its trigger-backed
  and audit-protection behaviour still degrades on a 0-trigger load.
* The brief's `notification-cron`/`process-scheduled` may be intended successors to `cron` — **not stated anywhere**;
  recorded only as a nearest analogue (§2.4).

### Missing evidence (nothing in the repository speaks to it)

Every row of §2.1's brief-name block; the source of all nine brief functions; every env-var name for them; their
schedules; their retry semantics; the deploy surface mechanics (§8.1); a push-token table/column; a queue table; the
`private.record_audit` caller; the `private.expire_stale_commands` caller; a Firebase-token verification path; a browser
export of the `_shared/` tree; the `pairing/` per-file artefacts.

### Unverified (explicitly not established here)

* Any runtime behaviour of any function — no request was ever made (E4 `:404`; E5 `NOT EXECUTED`).
* Whether the evidenced nine are **still** the deployed set.
* Whether production secrets exist.
* Whether `verify-firebase-token` is correct, incorrect, present, or absent — §5.4.
* Whether staging is currently reachable or has auto-paused since 2026-11-02T07:16Z (deadline 2026-11-06, now past,
  un-owned).
* Whether RLS deny-all would break any function: **it would not**, because all nine use `service_role`, which bypasses
  RLS (`90-limitations.md`:112; E4 `:245`) — but that is a *reason deployment looks superficially feasible* and is
  precisely why the 0-RPC situation is the real blocker.

### Recommendations (to the lead auditor; none is an action this audit took)

1. **Re-baseline the brief before anything else.** Ask the owner to state, per function, whether the name is (a) an
   intended future slug, (b) a recollection of a slug that exists on a surface this programme cannot see, or (c) an error.
   Until answered, treat the nine names as **design intent, not inventory**, and do not let them enter any patch, plan of
   record, or approval fence as though evidenced (A4-F01).
2. **Force the auth decision into one written amendment.** The recorded architecture rows
   ([02-architecture.md:200](../stage1/02-architecture.md), `:205`; `SETUP-CHECKLIST.md:16`) and the owner's direction
   disagree about who issues identity. That single decision determines whether 8 of 9 evidenced handlers need re-plumbing,
   and whether `verify-firebase-token` is even the right shape. No gate currently covers it (A4-F11).
3. **Do not put A8 to the owner without A7, and do not put A7 without naming who holds the credential.** A7 forbids the
   only artefact the programme holds (minified bundles) — the deploy lane is procedurally dead until A7 closes (A4-F07).
4. **Sequence the push lane as DDL first, functions second.** No token storage exists; that is A3/schema scope, not A8
   scope (A4-F06). Bundling "add `register-token`" with "add a `devices` column" would hide a schema change inside a
   function deploy.
5. **Do not sign A3 to "make Edge work."** A structural-only load leaves 0 of 38 RPCs, so all eight RPC-dependent
   functions stay broken while adding a durable, non-undoable mis-baseline (no backups/PITR, 0 slots, delete-and-re-create
   withdrawn) — [S2-EXEC-04-a3-precondition-matrix.md](S2-EXEC-04-a3-precondition-matrix.md):110-118.
6. **Answer the two standing cron questions in writing**: who invokes `cron`, and is `pg_cron` installed
   ([01](01-staging-project-proposal.md):284; `parts/A-staging-spec.md:198`). "Unknown" is a legitimate answer; silence is not,
   because R-05's correctness depends on it.
7. **Extend the register before creating a secret**, per the programme's own rule "Any new secret gets a row in §1 before
   it is created, not after" ([06](../stage1/06-secrets-and-environments.md):46) — this applies to any `FCM_*`, mail-provider or
   WhatsApp-credential name the brief's set would require (§7).
8. **Refer A4-F13 to the evidence-management lane**: the empty `pairing/` directory should either be populated from the
   `E1 shared[]` rows or annotated as intentionally empty, so a later reader does not assume lost evidence.

---

## 12. No operational action by this document

Producing this file involved: **no browser page opened; no dashboard, console or project URL visited; no CLI command; no
REST/API/hidden-endpoint call; no direct database connection; no SQL of any kind (including any count on `auth.users`); no
function invoked, deployed, edited, listed or log-queried; no secret read, listed, created, rotated or requested; no
Firebase action of any kind; no production surface touched** (the evidenced Edge inventory is cited from its 2026-10-30
capture file, never re-read); **no existing file modified; no patch touched; no approval fence signed, drafted, prefilled
or dated; no git operation performed.** The only operations used were file reads, `ls`, `wc`, `grep`, `sha256sum`, and
local read-only parsing of in-repo JSON evidence. **Exactly one new file was created: this one.**

This file authorises nothing by existing. It does not constitute A3, A5, A7, A8, A9, A12 or any other approval; it
ratifies nothing; it closes no gate; and it converts no unsigned block into an executable one.
