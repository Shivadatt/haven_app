# 03 — Data model: proposed model vs existing schema

Derived from [01-baseline-inventory.md](01-baseline-inventory.md) (read-only discovery, 2026-10-29) and governed by the gates in [05-change-plan.md](05-change-plan.md).
**No database change has been made. Nothing in this document has been created, applied or executed.**

## 0. How to read this document

| Constraint | Consequence |
| --- | --- |
| Column names and types were captured by Q8 after this mapping was drafted | Every mapping below should be read against [g1-q8](evidence/g1-q8-20261029.json); names and types are confirmed, and §5 tracks what is still open. |
| RLS flags and policy bodies are now observed | Access-path claims defer to [04-rls-matrix.md](04-rls-matrix.md) §0a. |
| Row counts are dashboard estimates, not `count(*)` | Volumes are indicative only. |
| No migration history exists | The live database is the only source of truth (gate G3). |

Verdict legend:

| Verdict | Meaning |
| --- | --- |
| **EXISTS** | A live table clearly serves the proposed entity's purpose. |
| **PARTIAL** | A live table covers part of the entity, or the mapping is plausible but unproven. |
| **MISSING** | No live table was observed for the entity. |
| **UNPROVEN** | Table exists but holds 0 rows, so no behaviour has ever been exercised. |

## 1. Coverage matrix

All 18 proposed entities, mapped to the 19 observed tables. Column-level fit is **unverified** in every row — see §5.

| # | Proposed entity | Working hypothesis | Verdict | Evidence (rows est.) | Note |
| --- | --- | --- | --- | --- | --- |
| 1 | profiles | `profiles` | **EXISTS** | 8 | Comment: row created by an `auth.users` trigger; role set once by an Edge Function. |
| 2 | families | `families` | **EXISTS** | 3 | Comment: one parent owner; soft-deleted via `deleted_at`. |
| 3 | family_members | `family_members` | **EXISTS** | 7 | SELECT policy only; membership writes are service-role. |
| 4 | devices | `devices` | **EXISTS** | 14 | 25 columns — widest table; may already embed device metadata and push state. |
| 5 | pairing_codes | `pairing_requests` + `device_pairing_tokens` + `pairing_attempts` | **PARTIAL** | 25 / 27 / 68 | Split across three tables. No single short-lived, human-typed code object is confirmed; code TTL, reuse and attempt-lockout semantics are unproven. |
| 6 | device_capabilities | possibly `device_apps` | **PARTIAL** | 2 | `device_apps` may be installed-app inventory rather than declared capabilities. 9 columns, 2 rows — too little behaviour to infer meaning. |
| 7 | policies | `device_policies` | **EXISTS** | 15 | One policy set per device is likely; effective-policy resolution and versioning unproven. |
| 8 | commands | `device_commands` | **EXISTS** | 17 | Realtime is **on**; 15 columns may already hold delivery/terminal state. |
| 9 | command_acks | — (possibly inside `device_commands` col. set) | **MISSING** | — | No acknowledgement table observed. Must not be assumed absent at column level until G1. |
| 10 | safety_events | `safety_alerts` | **PARTIAL** | 2 | Alerts look like a notification/decision output, not a raw detection event log. Only 2 rows ever. |
| 11 | location_points | `location_events` | **EXISTS** | 1,773 | Largest table by far; 84.6% of all rows together with `webrtc_signals`. |
| 12 | geofences | `safe_zones` + `safe_zone_states` | **UNPROVEN** | 0 / 0 | Both empty. CRUD policies exist on `safe_zones`; `safe_zone_states` is deny-all (RLS on, no policy). |
| 13 | live_sessions | `remote_sessions` + `webrtc_signals` | **PARTIAL** | 39 / 1,093 | Session metadata and signalling are separate; no TURN/credential lifecycle visible. |
| 14 | push_tokens | — | **MISSING** | — | No device-token table. `devices` (25 cols) may hold one token; multi-token/rotation is unproven. |
| 15 | subscriptions | — | **MISSING** | — | No entitlement or billing table of any kind. |
| 16 | audit_logs | `audit_logs` | **EXISTS** | 262 | 9 columns. Whether writes are trigger-driven or function-driven is unknown. |
| 17 | consents | — | **MISSING** | — | No consent/acceptance record. |
| 18 | deletion_jobs | — | **MISSING** | — | No queue or state table for erasure/retention work. |

Existing tables **not** in the proposed list — they still need a home in the model:

| Table | Rows est. | Provisional role |
| --- | --- | --- |
| `child_contact_ids` | 4 | Stable child identifier to initiate pairing; comment states "identifier only, never a credential". Belongs to the pairing/auth boundary, not the domain model. |
| `pairing_attempts` | 68 | Abuse/rate-limit evidence for pairing; also mapped into entity #5. |
| `webrtc_signals` | 1,093 | Transport buffer for SDP/ICE, not a record of anything (see §3). |
| `usage_daily` | 29 | Pre-aggregated per-device daily usage; already a minimised form. |

## 2. Gaps that matter for a parental-safety product

Field lists below are **shape descriptors** — purpose and constraints, not column names or types. No name or type is asserted, and none may be inferred from this table.

| Gap | Why it matters | Minimum shape (requirements, not DDL) | Stage |
| --- | --- | --- | --- |
| **Push token storage** | Without server-side tokens a parent never learns of an alert, a pairing request or a command result. Alerting is the product. FCM is blocked by gate G2, but the storage decision is not. | One row per (device, token); token value treated as a secret and never logged; platform discriminator; issuance and last-seen timestamps; revocation state; uniqueness so a token cannot bind to two devices; purge on revoke. Today `devices` may hold a single token — must be verified before assuming multi-device support. | **Stage 1 decision** (build Stage 2, after G2) |
| **Command acknowledgement / idempotency** | A command that is silently lost looks identical to a command that was refused. Retries without a dedupe key can execute twice (e.g. a remote-session start or a policy wipe). | Per-command terminal state with timestamps; at-least-once delivery plus an idempotency key unique per (device, command) so replay is a no-op; explicit failure reason codes; ack retention shorter than command retention. Prefer a **new** table over altering `device_commands`. | **Stage 1 verification**, build Stage 2 |
| **Consents** | The product stores a child's location history. App-store family policy and privacy law both require demonstrable, versioned consent from the guardian, and re-consent when terms change. An inference from "account exists" is not evidence. | Append-only acceptance records: who accepted, in what capacity (guardian), which document and which version, when, and from where (coarse); supersession link to the prior version; never updated in place. | **Stage 1 decision**, build Stage 2 |
| **Deletion jobs** | `families` is soft-deleted by comment, so data outlives the request. Erasure must reach 19 tables plus storage plus FCM tokens, and must be auditable. | Durable request record with requester, scope (family / device / profile), state machine, attempt counter, terminal outcome, and a completion timestamp; idempotent per request; never deleted itself while audit retention applies. | **Stage 1 decision**, build Stage 2 |
| **Entitlements / subscriptions** | Free tier is NANO with 500 MB DB and 5 GB egress; precise location and signalling grow fastest. Without an entitlement record there is no way to bound a family's history or feature set. | Entitlement per family: plan identifier, validity window, state, provider reference kept **outside** this schema where possible; no card data, ever; history of changes rather than overwrite. | **Stage 2** (billing is out of scope for Stage 1) |
| **Retention of precise location** | 1,773 precise points already exist for 3 families with no visible expiry. Precise coordinates are the highest-risk data class in the product. | Explicit window per data class; a purge path that the existing `cron` function can drive; an aggregated form retained longer than raw; documented per-family override; verifiable by a count query. | **Stage 1 decision**, build Stage 2 |
| **Device capability declarations** | Policy sync and remote sessions depend on what the child device can actually do (location permission, accessibility, overlay, battery-optimisation exemption). Silent mismatch reads as a broken product. | One row per (device, capability): supported flag, granted flag, declaration source, observed-at timestamp, app version. Keep separate from installed-app inventory if `device_apps` proves to be a package list. | **Stage 1 verification**, build Stage 2 |

## 3. Retention and minimisation

Principles, in priority order:

1. **Signalling blobs are transport, not records.** An SDP/ICE payload is worthless minutes after the session ends and is the most sensitive artefact in the system. Delete on session end; a hard ceiling applies regardless of session state.
2. **Raw beats nothing, but aggregates beat raw.** Keep precise history only as long as a parent-facing feature needs it; keep a daily aggregate far longer.
3. **Retention is a schema decision, not a cron setting.** Every class needs an owning table, a stated window and a purge path before any client writes to it.
4. **Nothing is retained "for debugging" without a named purpose and an end date.**
5. **Minimise at write time.** Do not store precision the feature does not use, and do not store the same fact in two tables.

| Data class | Table(s) | Volume est. | Sensitivity | Proposed window | Disposition |
| --- | --- | --- | --- | --- | --- |
| Precise location points | `location_events` | 1,773 | **Critical** | 30 days raw (7–90 configurable) | Then aggregate to per-device daily; delete raw rows. |
| WebRTC signalling | `webrtc_signals` | 1,093, growing | **Critical** | ≤ 1 hour, deleted at session end | Hard delete; no analytics, no long-term backup. Treat current 1,093 rows as backlog to purge once ownership is verified. |
| Session metadata | `remote_sessions` | 39 | High | 90 days | Retain for parental transparency; no media stored. |
| Safety alerts | `safety_alerts` | 2 | High | 12 months | Retain; alert content may quote location — apply the location rule to it. |
| Usage aggregates | `usage_daily` | 29 | Medium | 13 months | Already aggregated; keep for year-over-year views. |
| Audit trail | `audit_logs` | 262 | Medium (contains actor refs) | 12 months, 24 for security-relevant actions | Append-only; purge by age, never by edit. |
| Pairing evidence | `pairing_requests`, `device_pairing_tokens`, `pairing_attempts`, `child_contact_ids` | 25 / 27 / 68 / 4 | **Critical** (tokens) | Codes: minutes, single-use. Attempts: 30–90 days. Contact IDs: life of the child profile | Expire and delete used/failed codes and tokens promptly; retain attempt counts, not payloads. |
| Command history | `device_commands` | 17 | Medium | 30 days after terminal state | Retain for support; purge resolved rows. |
| Policy snapshots | `device_policies` | 15 | Medium | Current + prior version | Superseded versions pruned after 90 days. |
| Installed apps | `device_apps` | 2 | High | Latest snapshot only | Overwrite per sync; do not accumulate history. |
| Geofences / states | `safe_zones`, `safe_zone_states` | 0 / 0 | High | Life of the family | Empty today — the window must be defined **before** the first write. |

## 4. Additive, approval-gated proposals

Rules that bind every row below:

- All items are **new objects only** — no `DROP`, no `RENAME`, no `ALTER` of an existing column, constraint or policy.
- Every item is **`PROPOSED — NOT APPLIED`** and requires the G1 verification in §5 plus the G3 baseline first.
- No item may be implemented by repurposing an existing table whose meaning is unconfirmed.
- No DDL is written here on purpose; shape is described as requirements.

| ID | Proposal | Additive shape | Depends on | Status |
| --- | --- | --- | --- | --- |
| P-01 | Command acknowledgement table | New table keyed to an existing command row; terminal state, reason, timestamps; unique idempotency key per (device, command); RLS deny-by-default with service-role writes only. | §5 A, D | `PROPOSED — NOT APPLIED` |
| P-02 | Push token registry | New table, one row per (device, token); revocation state; uniqueness on token; no token value in logs or backups exposed to clients. | G2, §5 B | `PROPOSED — NOT APPLIED` |
| P-03 | Consent ledger | New append-only table; guardian subject, document identifier, version, accepted-at, coarse source; no in-place updates. | §5 A, C | `PROPOSED — NOT APPLIED` |
| P-04 | Deletion job queue | New table with explicit states and attempt counting; purge path across all 19 tables plus storage; itself exempt from its own purge while audit retention applies. | §5 B (FK/cascade), P-03 | `PROPOSED — NOT APPLIED` |
| P-05 | Device capability declarations | New table, one row per (device, capability); supported/granted/observed-at; kept distinct from `device_apps` unless §5 proves otherwise. | §5 A | `PROPOSED — NOT APPLIED` |
| P-06 | Entitlement record | New table per family with plan, validity window and state; provider identifiers only, no payment data. | Stage 2 scope | `PROPOSED — NOT APPLIED` |
| P-07 | Retention policy + purge routine | New configuration table for per-class window, plus a scheduled purge driven by the existing `cron` function; dry-run mode reporting counts before deleting. | §5 A, B | `PROPOSED — NOT APPLIED` |
| P-08 | Baseline migration (G3) | Records current schema as-is; additive to the repository only, changes nothing in the database. | G1 | `PROPOSED — NOT APPLIED` |
| P-09 | Supporting indexes | New indexes only, chosen from observed query shapes in the Edge Functions; no index changes to existing constraints. | §5 B, and Edge Function review | `PROPOSED — NOT APPLIED` |
| P-10 | Notifications-preferences table | Quiet hours and per-alert-class delivery choice, per guardian and per device. | G2, P-02 | `PROPOSED — NOT APPLIED` |

Explicitly **not** proposed in Stage 1: rewriting `pairing_codes` semantics, splitting `safety_alerts` into events + notifications, partitioning `location_events`, or extending the WebRTC path. Those need their own review after §5 and are listed as open questions in [05-change-plan.md](05-change-plan.md).

## 5. Verification needed before any migration is written

Each row was a fact that had to be captured read-only before §4 could become DDL. The G1 run on 2026-10-29 captured A1–A5
and B1–B4 as [g1-q1…q10](evidence/); the table is kept as the provenance map. The B3b run on 2026-10-30 then read the five
membership/helper bodies (`is_family_parent`, `is_family_member`, `shares_active_family`, `realtime_topic_allowed`,
`handle_new_user`) and all five trigger bodies; 11 `private` RPC implementations, 12 `public` bodies and
`private.record_audit` remain unread and are the remaining dependency for reusing the RPC layer.

| # | Fact to capture | Catalog source | Why it blocks the design |
| --- | --- | --- | --- |
| A1 | Column names, data types, nullability, defaults for all 19 tables | `information_schema.columns` | Every mapping in §1 is a hypothesis until this exists. |
| A2 | Primary keys and foreign keys, including `ON DELETE` behaviour | `pg_constraint` | Decides whether `deletion_jobs` can cascade or must enumerate. |
| A3 | Unique constraints and indexes, with definitions | `pg_indexes`, `pg_constraint` | Idempotency (P-01) and token uniqueness (P-02) need to know what is already enforced. |
| A4 | Check constraints and enum/domain types | `pg_constraint`, `pg_type` | Command states, roles and alert severities must reuse existing vocabularies, not invent parallel ones. |
| A5 | Column defaults for identifiers (uuid vs serial, generator function) | `pg_attrdef` | New tables must match the existing convention. |
| B1 | RLS enabled flag per table | `pg_class.relrowsecurity` | Answered 2026-10-29: enabled on all 19, forced on none ([g1-q1](evidence/g1-q1-20261029.json)). |
| B2 | Policy expressions (`USING`, `WITH CHECK`) and roles | `pg_policies` | Feeds [04-rls-matrix.md](04-rls-matrix.md); determines whether new tables can follow the same helper functions. |
| B3 | Grants to `anon`, `authenticated`, `service_role` | `information_schema.role_table_grants` | Write-path assumptions ("service-role only") are currently inferred from missing policies. |
| B4 | Functions, language, `SECURITY DEFINER`, fixed `search_path` | `pg_proc` | Existing RPC helpers may already implement policy or membership checks worth reusing. |
| C1 | Triggers per table, especially on `auth.users` → `profiles` and any audit trigger | `pg_trigger` | Determines whether `audit_logs` fills automatically; affects P-03/P-04 design. |
| C2 | Realtime publication membership | `pg_publication_tables` | Four tables are on; new tables must not silently join a broadcast. |
| C3 | Extensions installed (e.g. crypto/uuid) and their schemas | `pg_extension` | Needed before choosing generator and hashing approaches. |
| D1 | Whether `device_commands` already carries ack/idempotency fields | A1 subset | Decides if P-01 is a new table or unnecessary. |
| D2 | Whether `devices` already stores a push token | A1 subset | Decides the scope of P-02. |
| D3 | Whether `device_apps` is an inventory or a capability declaration | A1 subset + Edge Function `device-register` review | Decides P-05 in full. |
| D4 | Payload sensitivity of `webrtc_signals` (metadata only, no payload dump) | A1 subset | Confirms the ≤ 1 hour window in §3. |
| D5 | Existing time/device indexes on `location_events` | B/A3 subset | A purge by age needs an index or it will scan and time out. |
| D6 | Whether `families.deleted_at` (per comment) has any consumer | Edge Function `family-admin` review | Soft delete without a purge path is the core of P-04. |

## 6. Status and cross-references

| Question | Document |
| --- | --- |
| What exists today, and how was it observed? | [01-baseline-inventory.md](01-baseline-inventory.md) |
| Who can read or write each table? | [04-rls-matrix.md](04-rls-matrix.md) — §0a (verified) |
| What is approved, gated or out of scope? | [05-change-plan.md](05-change-plan.md) |
| How will changes be proven? | [08-test-matrix.md](08-test-matrix.md) |

| Item | State |
| --- | --- |
| Mappings in §1 | `HYPOTHESIS — awaiting SQL verification` |
| Gaps in §2 | `IDENTIFIED — not designed, not applied` |
| Retention windows in §3 | `RECOMMENDATION — not enforced anywhere` |
| Proposals in §4 | `PROPOSED — NOT APPLIED` (all 10) |
| Schema changes made by this document | **None** |

## 6. Verification update (second read-only pass, 2026-10-29)

Column names, types and constraint flags are now captured for all 19 tables ([evidence/schema-columns.md](evidence/schema-columns.md)), so the hypotheses in §1 can be graded against structure rather than intent. Column-level facts still missing: defaults, FK targets, delete rules, unique indexes, check constraints.

| Gap from §2 | Status after structure capture | Basis |
| --- | --- | --- |
| Push tokens | **Still missing** | No token column on `devices`, no `push_tokens` table. This is the only unambiguous FCM gap. |
| Command acknowledgement | **Already covered** | `device_commands.acked_at`, `result`, `error_message`, `attempts`, NOT NULL `idempotency_key`. No `command_acks` table needed. |
| Policy acknowledgement / idempotency | **Already covered** | `device_policies.acknowledged_at`, `enforcement_status`, `last_error`; `apply_policy_version(..., p_idempotency_key)` |
| Device capabilities | **Partially covered** | `devices` permission flags (`usage_access_granted`, `location_granted`, `background_location_granted`, `camera_granted`, `microphone_granted`, `notifications_granted`) + `device_apps`. A separate capability table is not justified. |
| Consents | **Partially covered** | Only `remote_sessions.consent_recorded` (bool). No consent version, scope or withdrawal record. |
| Deletion jobs | **Still missing** | No job/queue table; `families.deleted_at`, `family_members.removed_at`, `child_contact_ids.rotated_at` imply soft-delete flows with no erasure execution record. |
| Entitlements / subscriptions | **Still missing** | No table. Deferred to Stage 2 unless billing is in scope. |
| Geofences | **Covered** | `safe_zones` (center + radius + active) and `safe_zone_states` (composite PK `zone_id, device_id`, `inside`) |
| Live sessions | **Covered** | `remote_sessions` with state timestamps, `consent_recorded`, `session_nonce`, `ended_by`/`ended_reason` |
| Location history | **Covered** | `location_events` (lat/lng float8, accuracy, recorded/received, source) |

Consequence: the additive proposal list in §4 shrinks to **push token storage, consent records, deletion/erasure records** — and each stays `PROPOSED — NOT APPLIED` behind [05-change-plan.md](05-change-plan.md) G3. No new table is justified by the captured structure for commands, acks, capabilities, geofences or sessions.
