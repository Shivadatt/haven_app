# F — E5, E6, E7: pairing hash hygiene and abuse budgets

> **WORKING PAPER — SUBORDINATE AND PARTLY SUPERSEDED (2026-11-02, S2-DOC-02).**
> `docs/stage2/00`–`06`, `README.md` and `evidence/S2-CREATE-01-new-projects.md` are the plan of record and the
> authoritative evidence. Where this part disagrees with them, those documents win. Statements below written before
> 2026-11-02 that describe staging as uncreated, or a plan step as approved/executed, are historical proposals, not
> current status. Read the dated addendum at the end of this file before acting on anything here.

Status: **DESIGN ONLY — NOTHING APPLIED**. No source, config, secret, SQL or deployment was touched. Labels: **VERIFIED**
(read in Stage 1 evidence), **INFERRED** (follows but a step was not observed), **PROPOSED — NOT APPLIED**. Links are
relative to this file.

Evidence base: [16-phase-e-findings.md](../../stage1/16-phase-e-findings.md#e5) (E5, E6, E7, E8),
[14-edge-function-security-audit.md](../../stage1/14-edge-function-security-audit.md) (checks 7, 11, 12),
[13-edge-function-source-inventory.md](../../stage1/13-edge-function-source-inventory.md) (dependency matrix, §6–7),
[06-secrets-and-environments.md](../../stage1/06-secrets-and-environments.md), [07-ops-and-observability.md](../../stage1/07-ops-and-observability.md),
[03-data-model.md](../../stage1/03-data-model.md), [15-edge-function-test-plan.md](../../stage1/15-edge-function-test-plan.md).

## 1. E6 — pepper fallback

### 1.1 Mechanism (VERIFIED)

`identifierHash(value, pepper?)` uses `pepper ?? Deno.env.get("PAIRING_HASH_PEPPER") ?? ""`; if the key length is 0 it
emits `pairing_hash_pepper_missing` once per isolate and returns plain `sha256Hex(value)`. Silent fail-open, no error,
no metric, no alert destination ([07 §5](../../stage1/07-ops-and-observability.md) records "Alert destination: none").
`pairing` calls it at `:566` (redeem attempt) and `:771` (invite attempt). Token rows use `sha256Hex` at `:478/:565`
and are looked up by the same digest at `:574-578` (VERIFIED). Whether the variable is set in production is
**NOT VERIFIED** — the value was never read.

### 1.2 Options

| # | Behaviour when the pepper is absent | Effect today | Cost / risk |
| --- | --- | --- | --- |
| A | Throw → `503 pairing_unavailable` on redeem/invite | Pairing stops dead | Outage if the pepper is genuinely unset; needs source + deploy + rollback text |
| B | Keep plain-SHA for the *count* query, refuse to write new `pairing_attempts` rows | Pairing keeps working, per-identifier limits stop counting | The 10/identifier and 3-pending/10-per-24h limits are computed from those rows, so B silently converts E6 into a partial E8; only the 5/10-min per-parent limit (keyed on `parent_user_id`) still holds. **INFERRED** from the read-then-act pattern in `_shared/rate_limit.ts` |
| C | Retain fallback, add presence check + log alert | No code change; behaviour unchanged | Only real if a log alert has a destination; today it does not |

**Recommendation:** C now, A as the target. C is deployable without source and closes the "nobody looked" gap; A is
the durable control but must not ship before §1.4 proves the pepper is present, or it stops all pairing.

### 1.3 Migration hazard, stated precisely

Turning the pepper on (or rotating it) makes every pre-cutover `pairing_attempts.code_hash` unmatchable by a new
lookup. The consequences are narrower than "old rows become unfindable":

- **Token redemption is unaffected.** `device_pairing_tokens.code_hash` is plain SHA-256 and never used the pepper
  (VERIFIED). Live codes and live invites keep working.
- **The per-identifier redemption counter (10 / 10 min) resets** at cutover: rows written seconds earlier will not
  match the new keyed hash. The per-parent counter (5 / 10 min) is keyed on a plain UUID column and continues.
- **The invite counters (3 pending, 10 / 24 h) reset** for the same reason, so a parent could get one extra window's
  allowance at the boundary. No lockout, no maintenance window.
- **Evidence comparability breaks** if attempts are retained 30–90 days ([03 §3](../../stage1/03-data-model.md)): an
  investigator cannot match a submitted identifier against rows from the previous era.
- **Open risk:** if any invite *token* hash were also `identifierHash`-derived, a flag-day change would make every live
  invite (24 h TTL) unredeemable. Stage 1 evidence says token rows are plain SHA-256, but only the `create` write was
  read. Confirm at export that no write to `device_pairing_tokens.code_hash` uses `identifierHash`; if one exists, the
  change needs a 24-h dual-read instead of a flag day. **NOT VERIFIED.**

PROPOSED (code-only, no DDL): prefix stored attempt hashes with `v1:`/`v2:`, so eras stay distinguishable across a
rotation. `code_hash` is `text`; the change must land on the write and count paths in one deploy.

### 1.4 Precondition check (presence, never value)

1. Dashboard → Project Settings → Edge Functions → Secrets lists **names** with masked values. Confirm
   `PAIRING_HASH_PEPPER` appears. Presence is necessary, not sufficient: an empty value gives the same key length 0.
2. `supabase secrets list` (owner, linked project) shows names and digests. Fine to share **names**; do not paste the
   digest column for a short human-chosen pepper — a low-entropy value is offline-guessable from its digest. The pepper
   should be ≥32 random bytes, generated and stored by the owner.
3. Runtime proof: after one real `pairing` invocation, the function logs must show no `pairing_hash_pepper_missing`.
   The warning fires once per isolate, so absence across a window that contains pairing traffic is meaningful;
   absence in an idle window is not.

### 1.5 Staged rollout (PROPOSED)

Export source (G3) → record the current digest `427d419d…` → presence check (§1.4) → non-prod verification if one
exists (none today, [06 §3](../../stage1/06-secrets-and-environments.md)) → deploy A → one redeem (expect 200) → 24 h
log watch → close. Any failure: redeploy the captured pre-change text.

## 2. E5 — unsalted token hash

Design (VERIFIED): 8 characters from a 30-symbol alphabet, CSPRNG with rejection sampling, 10-min TTL, single use; the
token column stores plain SHA-256.

**Entropy arithmetic (VERIFIED inputs):** 30⁸ = 6.56 × 10¹¹ ≈ 39.3 bits. At 10¹⁰ SHA-256/s (one modern GPU) the whole
space falls in ~66 s, inside the 10-min window; at 10⁹/s it is ~11 min. So unsalted SHA-256 is **not** defensible on
preimage cost. It is defensible on the access and impact chain:

1. The attacker needs a database read. All 19 tables are API-disabled, the four pairing tables are RLS-enabled with
   zero policies, and Edge uses service-role only ([14 check 12](../../stage1/14-edge-function-security-audit.md)).
2. A recovered code yields one pairing request into the attacker's own family, visible to and approvable only by the
   child; rate limits and single-use still apply.
3. Impact is consent spam, not device or account access ([16 E5](../../stage1/16-phase-e-findings.md#e5)).

**Recommendation: accept-and-document for Stage 2**, with the load-bearing assumption written down — "no untrusted
party has read the database" — and an upgrade trigger: any dump exposure, read-grant/exposure regression, or a future
lower-entropy code.

**Keyed upgrade cost:** lookup becomes `identifierHash`; existing rows cannot be rehashed, so dual-read
(`identifierHash` first, `sha256Hex` fallback gated on `created_at < cutover`) for one invite TTL (24 h), then revoke
legacy active rows and drop the fallback. One function, so create and redeem change atomically; no client change.
Rollback makes new-scheme rows unredeemable — revoke them (10-min codes, 24-h invites).

Third option, cheaper than HMAC but client-visible: mint 10 characters → 30¹⁰ ≈ 49 bits ≈ 16 h at 10¹⁰/s, only if the
parent input is not length-fixed. **NOT VERIFIED** (client source unavailable).

## 3. E7 — measurement-first framework

E7 is a **capacity and consent-integrity** control, not an authorisation control. A false positive must degrade the
abuser, never the fleet.

### 3.1 Measurement questions

| Q | Question | Source (read-only) | Caveat |
| --- | --- | --- | --- |
| Q1 | Telemetry cadence per device: p50/p95/p99 inter-upload interval | `location_events.received_at` deltas per `device_id`; `usage_daily` write cadence | `recorded_at` is client clock (bounded −7 d…+5 min) — never use it for rate maths |
| Q2 | Burst shape: max uploads per device per 1/10/60 min | same tables, bucketed | Heartbeat leaves no history: `devices` keeps only the latest timestamp, so heartbeat cadence must be inferred or measured forward |
| Q3 | Requests vs rows | rows per request are unbounded (`usage_upload` accepts 500 entries) | Row cadence under-sizes a request-based limit by up to 500×; use row-based limits for storage, request-based for CPU |
| Q4 | Diurnal/fleet peak | concurrent per-device rates × 14 devices | 10 MAU, 14 devices — small-n, so p99 is one device |
| Q5 | Retry multiplier | duplicate `recorded_at`/`idempotency_key` ratios | Distinguishes retry from abuse before a budget is set |

p95/p99 must be computed from **server arrival** (`received_at`), over the longest available history, in the dashboard
SQL editor; the 1,773 location rows are the only meaningful sample today.

### 3.2 Candidate limits (values left blank on purpose)

| Action | Identity key | Candidate window | Limit | Primary measurement | Why meter it |
| --- | --- | --- | --- | --- | --- |
| `remote-session.request` | parent, per device | 10 min | SET FROM MEASUREMENT | `remote_sessions.created_at` | cheapest consent spam; interacts with E4 |
| `device-command.create` | parent, per device | 1 h | SET FROM MEASUREMENT | `device_commands.created_at` | notification/FCM amplification, row growth |
| `device-telemetry.location_upload` | device | 1 h (rows) | SET FROM MEASUREMENT | `location_events` count per device/hour | largest storage growth (500 MB cap) |
| `device-telemetry.usage_upload` | device | 1 day (rows) | SET FROM MEASUREMENT | `usage_daily` rows/day/device | 500-entry batches |
| `device-telemetry.heartbeat` | device | 1 h | SET FROM MEASUREMENT | forward instrumentation only | dedupe window already 6 h for low-battery |
| `device-register.register` | child | 1 h | SET FROM MEASUREMENT | `audit_logs` device_registered | re-credential churn |
| `family-admin.recover_device` / `purge_data` | parent | 1 h | SET FROM MEASUREMENT | `audit_logs` | destructive/expensive |
| `auth-bootstrap.create_family` | user | — | one active family (existing) | handler already enforces | lowest priority |

Every value stays `SET FROM MEASUREMENT`. Stage 1's illustrative 5/10 min and 60/h are **not** adopted here; they were
explicitly flagged as guesswork ([16 E7](../../stage1/16-phase-e-findings.md#e7)).

### 3.3 Storage options

| Option | Works? | Notes |
| --- | --- | --- |
| DB rolling counter `(key, window_start) → count`, one atomic `insert … on conflict do update … returning` | Yes | Also fixes E8's count-then-act. One upsert per metered request; prune with the existing `cron` function |
| Advisory lock + count on the target table | Yes, for low-volume endpoints | No new table; count cost grows with the table, needs an index on `(device_id, created_at)` |
| Stateless Edge memory | **No** | Isolates are per-instance and horizontally scaled, recycled on idle, with no request affinity: N instances each allow the full budget and every cold start resets it. Effective limit = configured × instances, which is a bypass, not a limit. This is why pairing already counts rows in `pairing_attempts` (VERIFIED) |
| Redis/Upstash | Technically yes | New paid service — excluded without written approval ([07 §6](../../stage1/07-ops-and-observability.md)) |

### 3.4 Write amplification and Free-plan cost

Counter rows/day = keys × (86,400 / window_seconds) × metered actions. At 60 keys and 1-min windows that is 86,400
rows/day (~10 MB/day) against a 32 MB / 500 MB database; at 1-h windows it is 1,440 rows/day. **A token bucket can cost
more storage than the abuse it prevents** — choose the coarsest window that still bounds the abuse, and never meter
telemetry at request granularity. Logging every 429 is worse: log ingestion is 0.17/1 GB and query 33.9/100 GB, the
tightest quotas in the system ([07 §2](../../stage1/07-ops-and-observability.md)); log once per window per key, or not
at all, and store the count in a table ([07 §5](../../stage1/07-ops-and-observability.md) already prefers a row over a log line).

### 3.5 Protect first

1. `remote-session.request` — cheapest to abuse, consent-integrity impact, low volume so a table count suffices.
2. `device-command.create` — notification and row amplification; idempotency absorbs retries, so the rest is deliberate.
3. Telemetry storage — highest growth, hardest to set safely; enforce as a generous row-count trigger after Q1–Q3.
4. `device-register`, then `family-admin.recover_device`/`purge_data`; `auth-bootstrap` last — already bounded.

## 4. Implementation order and blockers

| # | Step | Blocked by |
| --- | --- | --- |
| 0 | Export Edge source into the repo (G3, [13 §7](../../stage1/13-edge-function-source-inventory.md)) | Owner credentials — blocks every code change |
| 1 | Pepper presence check + `pairing_hash_pepper_missing` log review | Nothing |
| 2 | Measurement queries (Q1–Q5), read-only | Nothing |
| 3 | E6 option C: ops procedure + alert destination | Step 1; a destination decision |
| 4 | E6 option A: fail-closed deploy | Steps 0–1; rollback text from step 0 |
| 5 | E5 decision: accept-and-document, or keyed upgrade | Step 0 for the upgrade only |
| 6 | E7 counter table + migration (also fixes E8) | G3 baseline + SQL approval, not Edge source |
| 7 | E7 wiring into handlers | Step 0 **and** original build source |

**The sharp blocker:** seven of nine functions are minified 2-line bundles; the export returns the bundle, not the
modules ([13 §7](../../stage1/13-edge-function-source-inventory.md)). They cannot be edited by hand, so E7 cannot be
wired into `remote-session`, `device-command`, `device-telemetry`, `device-register`, `device-policy`, `family-admin` or
`auth-bootstrap` until the original source is recovered. Until then the only implementable enforcement is **database
side** (partial unique index for E4, row-count trigger for telemetry storage) — PROPOSED, needs DDL approval. E6 and E5
apply only to `pairing`, which is readable, but are still gated: without step 0 there is no diff and no rollback text.

## 5. Rollback and approvals

| Change | Rollback | Approval |
| --- | --- | --- |
| Set `PAIRING_HASH_PEPPER` | Unset; pairing keeps working via fallback | Owner; config change |
| E6 fail-closed deploy | Redeploy captured pre-change text (`427d419d…`), fallback returns | Owner; change record with digest before/after |
| E5 keyed upgrade | Revoke new-scheme rows (≤10 min codes, ≤24 h invites); revert code | Owner; no client change |
| E7 limits | Raise the config value or flip the disable flag — no deploy | Owner; values must live in config, not code |
| E7 counter table / trigger | `drop table` (counters only) / `disable trigger` | Owner; DDL per [07 §4](../../stage1/07-ops-and-observability.md) |

Gap to record, not paper over: a single owner and no second approver ([06 §1](../../stage1/06-secrets-and-environments.md)).
Propose a written change record plus a cooling-off period between "approved" and "deployed" for anything touching
pairing. No secret value is read, printed or pasted at any step.

## Open questions

1. Is `PAIRING_HASH_PEPPER` set in production, and is its value high-entropy? (presence can be checked; value must not be)
2. Does any write to `device_pairing_tokens.code_hash` use `identifierHash`? This decides flag day vs 24-h dual-read for E6.
3. What is the real telemetry cadence, and are requests batched beyond the 500-entry cap?
4. Is the parent's code input length-fixed (decides whether a 10-character code is a cheap E5 mitigation)?
5. Is the original build source for the seven minified functions recoverable (decides whether E7 is implementable at all)?
6. Which alert destination exists, if any?

## Addendum — S2-DOC-02 status correction (2026-11-02)

- **Still DESIGN ONLY — nothing applied.** No deploy, no secret set, no log reviewed, no counter table created. The three SQL patches are likewise `PROPOSED — NOT APPLIED`, and defects D-01…D-12 remain OPEN.
- **§4 step 0 has not happened and A7 (Edge source export to the repo) is unsigned and unexecuted.** No Edge Function source exists in this repository, so **E6, E7, E8, E9, E10 and E12 all stay blocked** — and G5-E is `BLOCKED — STAGING FUNCTIONS NOT DEPLOYED`.
- **§1.5's "non-prod verification if one exists (none today)" is superseded**: the staging shell EXISTS (`parent-control-staging`, ref `dzonzgngwxclhfnvxtvu`, `ap-northeast-2`, Free/NANO — [S2-CREATE-01](../evidence/S2-CREATE-01-new-projects.md)), but it is an **empty shell** — 0 tables, no schema, no `private.s2_environment` sentinel, **no secrets**, no test principals, no functions. So the §1.4 pepper-presence check was never performed anywhere and `PAIRING_HASH_PEPPER` presence remains NOT VERIFIED; no function logs exist to review.
- **A4 does not exist** in the plan of record (which uses A0–A3 and A5–A13); the creation was executed on the owner's direct instruction and is an executed action **awaiting retrospective ratification**, not a signed approval. [`approval-package-a0-a2.md`](../approval-package-a0-a2.md) is `SUPERSEDED — DO NOT SIGN`; the replacement package's A2′ authorises the sentinel and approved settings only — no schema load, no secrets.
- **Slots: 2 active / 2 used / 0 remaining** on Free, so no second or throwaway staging project is available for any E5/E6 dual-read rehearsal.
- Firebase is intended for FCM push transport only and **FCM is not configured**: the `haven-staging` shell (`haven-staging-46822`, project number `381273275501`, Spark) has **zero apps and zero credentials**, and Firebase Auth is to remain disabled — Supabase Auth is the only identity authority (all 9 Edge handlers call `db.auth.getUser(token)`). Creating that shell crossed the A12 boundary; A12 remains unsigned and no further Firebase action is authorised by this part.
- Free-plan auto-pause: a dated dashboard touch is required **on or before 2026-11-06** (approximate — no start timestamp was recorded). Screenshots were never captured, so §1.4/§1.5 log- and dashboard-based claims are `NOT VERIFIED`.
- No operational action taken in this pass — no browser, dashboard, CLI, secret, deploy or signature.
