# 07 — Operations and observability

How this stack is run today, how much quota is left, what recovery actually exists, and the minimum process needed to change production safely.
Inputs: [01-baseline-inventory.md](01-baseline-inventory.md), [02-architecture.md](02-architecture.md), [04-rls-matrix.md](04-rls-matrix.md), [05-change-plan.md](05-change-plan.md), [06-secrets-and-environments.md](06-secrets-and-environments.md).

**Evidence rule for this document:** every row carries a status. `VERIFIED` means observed in the 2026-10-29 read-only discovery. `NOT VERIFIED` means it was not observed and must not be assumed either way. `PROPOSED` means it does not exist yet and is a recommendation only. **No backup, restore, alert, drill or test has been performed**, and no paid service is recommended.

## 1. Current operational posture

| Area | Observed state | Evidence | Status |
| --- | --- | --- | --- |
| Environments | Exactly one, `prod`: `parent-control-prod` / `hhqgreaoqulmfwfwarhc`, ap-northeast-2, NANO | [01](01-baseline-inventory.md) §1 | VERIFIED |
| Plan | Free | Dashboard quota panel | VERIFIED |
| Schema | 19 tables in `public`, 4 realtime-enabled (`device_commands`, `remote_sessions`, `safety_alerts`, `webrtc_signals`) | [01](01-baseline-inventory.md) §2 | VERIFIED |
| Migration tracking | None. Migrations page shows the empty "run your first migration" state | [01](01-baseline-inventory.md) §5 | VERIFIED |
| Schema provenance | Created outside a tracked flow; live DB is the only source of truth | [01](01-baseline-inventory.md) §5 | VERIFIED |
| Local stack | Unavailable — no Docker, so `supabase start` cannot run; `psql` absent | [01](01-baseline-inventory.md) §8 | VERIFIED |
| CLI project state | `supabase/config.toml` present, `migrations/` and `functions/` empty | Repo contents | VERIFIED |
| Function deployment path | 9 functions live, deployed 2–3 days before capture, **no source in this repo** — so they were not deployed from here | [01](01-baseline-inventory.md) §3 | Deployment path NOT VERIFIED |
| Data access model | All 19 tables API-disabled; all access server-side via the 9 functions | [01](01-baseline-inventory.md) §2 | VERIFIED (per-table toggle) |
| RLS flags | Enabled on all 19, forced on none, owner `postgres` | [g1-q1](evidence/g1-q1-20261029.json), [04](04-rls-matrix.md) | VERIFIED (G1, 2026-10-29) |
| Backups | No backup list, schedule or last-run timestamp was observed | — | NOT VERIFIED |
| Restore | Never attempted by anyone on this project | — | NOT TESTED |
| Alerting | No alert destination or on-call route is documented in the repo; whether dashboard alerts exist was not inspected | — | NOT VERIFIED |
| Error reporting | No Sentry/OTel/APM dependency and no function source in the repo | Repo contents | No reporting present |
| CI/CD | No pipeline, no `.github/`, repository has zero commits | Repo contents | VERIFIED absent |
| Log access | Dashboard log surfaces only; ingestion 0.17 GB, query 33.9 GB | [01](01-baseline-inventory.md) §1 | VERIFIED |
| Operator access | No access token and no DB password on this machine; read-only SQL is available through the dashboard SQL Editor, which is how G1 ran | [01](01-baseline-inventory.md) §9 | VERIFIED (G1 answered 2026-10-29) |
| Ownership | Single owner account for the whole org; no second approver, no on-call rota | [01](01-baseline-inventory.md) §1 | VERIFIED as single-owner |
| Uptime target / SLA | None recorded; Free plan | — | NOT VERIFIED |

Net effect: production is **running but only partly operable**. Read-only SQL is now available in the dashboard, but nobody can take a dump, apply a migration, or roll back a change without first answering G3; and no restore has ever been tested (N1).

## 2. Quota headroom

| Dimension | Used | Limit | Headroom | % used | Practical ceiling | Watch |
| --- | --- | --- | --- | --- | --- | --- |
| Database size | 32 MB | 500 MB | 468 MB | 6.4% | The 500 MB cap, not the headroom, is the long-term constraint: two append-only tables already hold ~85% of the ~3,388 estimated rows (`location_events` 1,773 + `webrtc_signals` 1,093) and no retention job was observed | Weekly size delta; a step change means a write path changed |
| Log query | 33.9 GB | 100 GB | 66.1 GB | **33.9%** | Tightest limit. Investigation itself burns it | Any incident review; keep time windows narrow |
| Log ingestion | 0.17 GB | 1 GB | 0.83 GB | 17% | Second tightest; verbose function logging would eat it | Volume per function, especially `device-telemetry` |
| Egress | 0.12 GB | 5 GB | 4.88 GB | 2.4% | Realtime fan-out and telemetry reads dominate it | Jump with no new installs = abuse or a polling bug |
| Monthly active users | 10 | 50,000 | 49,990 | 0.02% | Non-binding at this scale | Only relevant if signups spike unexpectedly |
| File storage | 0 B | 1 GB | 1 GB | 0% | Unused; no bucket activity observed | Any non-zero value means an unplanned feature |

Two consequences worth stating plainly:

- The binding constraints are **observability limits**, not capacity limits. A serious incident consumes log query, which is the resource needed to diagnose it.
- Exceeding a Free-plan quota is an **availability** risk (project restriction), not an invoice risk — the exact enforcement behaviour was not observed and is **NOT VERIFIED**. Do not plan around either outcome.
- Whether `cron` performs any retention or purge is unknown: the function name suggests scheduled work, but its body is not in the repo and could not be read. **NOT VERIFIED** — do not assume telemetry is being pruned.

## 3. Backup and restore

| Item | Status | Note |
| --- | --- | --- |
| Automated backups exist | NOT VERIFIED | Nothing on the dashboard was read that proves a schedule exists |
| Retention window / PITR | NOT VERIFIED | Free plan entitlements differ from paid tiers; assume nothing |
| Last successful backup | NOT VERIFIED | No timestamp observed |
| Off-site logical dump | None | `migrations/` is empty; no dump artifact in the repo |
| Restore ever tested | **NO** | Never performed; no procedure, no evidence |
| RPO / RTO | Undefined | Cannot be stated without the two rows above |
| Schema recoverability | Partial | Table, policy, trigger, index and grant definitions are known from G1/B3b, but 24 function bodies and the `auth.users` trigger are not in a restorable artefact, and no baseline dump exists yet (G3). The schema is **not** reconstructible from documentation alone |

Worst-case assumption to plan against: total loss of the 19 tables, 8 profiles and 10 MAU accounts with **no** recoverable copy, because the only complete description of the schema is the live database itself.

What must be true before a backup can be claimed: (a) catalogue access (answered by G1), (b) a successful `supabase db dump` producing a file, (c) that file restored into a non-production target, (d) row counts and `db diff` matching. Until (d) passes, this section reads "no verified recovery capability".

**Restore drill — proposed, not performed:**

1. Precondition: G1 answered; a target that is **not** `prod`.
2. Capture: schema-only dump (`supabase db dump --schema public --schema private`), plus a data-only dump if data recovery is in scope. The `private` schema is not optional — it holds the implementations behind the `public` wrappers.
3. Target options: the local stack is **blocked** (no Docker); a scratch hosted project is **blocked** on an approval/cost decision. Both are recorded blockers, not steps to improvise.
4. Load, then prove parity: `supabase db diff` must report no changes against the G3 baseline, `migration list` must show local == remote, and per-table row counts must match the pre-drill capture.
5. Expect a partial result even on success: a schema dump does **not** restore `auth.users` accounts or storage objects. Account recovery has no path here; storage is 0 B today.
6. A data dump contains real family and location data — store encrypted, never commit, delete after the drill.
7. Record the measured RTO and the exact gaps in `docs/stage1/evidence/` (directory planned in [05](05-change-plan.md)).

## 4. Migration workflow proposal

There is no rehearsal environment, so every migration is a production migration. The process has to compensate for that.

| Step | Action | Gate | Safety property |
| --- | --- | --- | --- |
| 0 | `supabase login`, `supabase link --project-ref hhqgreaoqulmfwfwarhc` | Operator credential (G3) | Token and DB password stay in the operator shell, never in the repo |
| 1 | Baseline capture: schema dump → `supabase migration repair --status applied <version>` → verify `migration list` parity and an empty `db diff` | G3 | Additive only; records state, alters nothing |
| 2 | Author one migration per change; review the SQL by hand | — | One change per file, timestamped, committed |
| 3 | `supabase db diff` **before** applying | Linked project (G3) | Must show only the intended objects; anything else is drift to investigate first |
| 4 | Apply with `supabase db push` during an announced window | approval | No `--include-all`, no `db reset`, no RLS disable, no destructive statement unattended |
| 5 | `supabase db diff` **after** applying | Linked project (G3) | Empty diff = local migrations and remote agree |
| 6 | Forward-fix on failure | — | Preferred default: a new migration that corrects state |
| 7 | Destructive rollback (drop column/table, restore from dump) | approval | Documented with its data-loss consequence **before** it is needed; never assumed safe because "we can roll back" |

Rules that follow from the missing environment:

- Prefer additive migrations (new column nullable, new table, new policy) so the app keeps working during the change.
- Never repair history to hide drift; a `db diff` that shows unexpected objects is a finding, not noise.
- A rollback that drops a column also drops its data. That is a documented consequence requiring approval, not an automatic escape hatch.
- Because 24 function bodies are not in the repo, a schema change and its matching function change can land out of sync. Until functions are source-controlled, every migration that touches a column used by a function needs an explicit deploy step listed in the change record.

## 5. Monitoring and alerting gaps

| Signal | Current state | Free, no-new-service proposal | Blocker |
| --- | --- | --- | --- |
| Edge Function errors | No error reporting, no source in repo | Structured single-line JSON logs (request id, function, route, status) with no PII and no secrets; review hosted function logs after each deploy | Source control of `functions/` |
| Function latency / timeouts | Not measured | Log duration per invocation; watch the slowest route (`device-telemetry`) | Same |
| Auth failure spikes | Not monitored; email-only provider, confirm-email on, signups on | Review auth logs on a fixed cadence; treat a burst of `otp`/password failures as a probing signal | Dashboard auth logs (no SQL needed) |
| Failed FCM sends | No FCM exists (G2) | Before enabling push, define a send-outcome counter (per-day `ok` / `error:<code>`) so failure is visible from day one | G2 |
| Pairing brute force | `pairing_attempts` holds 68 rows, RLS on, zero policies → service-role read only | Hourly-bucket query counting attempts per device/IP and per code; alert on a threshold. Also confirm token TTL and single-use on `device_pairing_tokens` (27 rows) | Read-only SQL access (dashboard); the function-source half was read in Phase E ([14](14-edge-function-security-audit.md) check 7) |
| Schema/RLS drift | Not monitored | Re-run the G3 no-diff check on a schedule; a non-empty diff is the drift alarm | G3 baseline |
| Realtime health | 4 tables live, no connection or error metrics | Sample a known pair of devices after each deploy; note the Free concurrent-connection ceiling is NOT VERIFIED | — |
| Quota burn | Manual dashboard only | Weekly check of the §2 table; log the numbers in the change record | — |
| Uptime / synthetic check | None | A single unauthenticated probe against one function endpoint, run by hand | A deployed function endpoint (none exists yet) |
| Alert destination | None documented | Pick one channel and record it; an alert with no destination is not an alert | Decision |

Design constraint: every proposal above avoids new paid services. It also has to respect §2 — more logging burns log ingestion and every investigation burns log query, so **prefer a row in a table over a log line**. A counter written to `audit_logs` (262 rows, parent-readable) is cheaper to query than a log scan and has no query-quota cost, provided no PII is written into it.

## 6. Cost exposure

| Limit (Free) | Cap | What would trigger an upgrade conversation | Consequence today |
| --- | --- | --- | --- |
| Database | 500 MB | Sustained growth in `location_events` / `webrtc_signals` without retention | Restriction or pause; exact behaviour NOT VERIFIED |
| Egress | 5 GB | Realtime fan-out growth or a client polling bug | Same |
| MAU | 50,000 | Genuine adoption; not plausible near-term from 10 | Same |
| Storage | 1 GB | Any feature that uploads files | Same |
| Log ingestion | 1 GB | Verbose function logging | Logs may be dropped or throttled; NOT VERIFIED |
| Log query | 100 GB | Investigation volume, dashboard usage | Query refusal; NOT VERIFIED |
| Projects per org | Not inspected | Creating `dev`/`staging` ([06](06-secrets-and-environments.md) §3) | Unknown |

**Rule:** no paid tier — Pro, compute add-on, PITR, larger disk, extra projects — is enabled without explicit written approval. This document recommends none. When a threshold in §2 is crossed, raise a decision item that quotes the measured number and the growth rate; do not pre-emptively upgrade, and do not silently accept data loss either. The only free levers are lower log verbosity, dropping unused realtime, and reducing client polling — data retention is a product decision, because deleting telemetry destroys evidence.

## 7. Production change-control checklist

| Phase | Check | Evidence to keep |
| --- | --- | --- |
| Pre-change | One change, one deploy; scope written down | Change note |
| Pre-change | `supabase db diff` captured and reviewed; anything unexpected explained | Diff output |
| Pre-change | Row-count baseline for affected tables (dashboard values are estimates — say so) | Numbers + capture time |
| Pre-change | No `DROP`, no RLS disable, no policy verb widening, no API exposure change | SQL review sign-off |
| Pre-change | Quota headroom checked against §2 | Current numbers |
| Pre-change | Rollback defined: forward-fix SQL drafted; any destructive path documented with its data loss | Draft migration |
| Pre-change | Approval recorded by the owner | Written approval |
| Change | Applied in a stated window, by one operator, with logs open | Timestamp, operator |
| Change | No `db reset`, no unreviewed `--include-all`, no ad-hoc SQL in the editor | Command list |
| Post-change | `db diff` shows only the intended objects; `migration list` parity | Diff output |
| Post-change | Each affected Edge Function invoked once; 2xx and no error lines | Function log excerpt |
| Post-change | The 4 realtime tables still deliver; one parent + one child device smoke test | Observation note |
| Post-change | Quota delta recorded (DB size, egress, log query) | Numbers |
| Rollback decision point | Pre-agreed triggers (error-rate, data corruption, latency) and a time box; on breach, execute the drafted forward-fix. A destructive restore needs fresh approval and a fresh dump first | Decision + timestamp |
| After | Outcome recorded; if the change failed, the failure becomes a finding, not a silent revert | Change note closed |
