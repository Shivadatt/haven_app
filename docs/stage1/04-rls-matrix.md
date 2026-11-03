# 04 — RLS and exposure matrix

Status: **`PARTIAL — EXPRESSIONS AND BODIES VERIFIED, LIVE TESTS NOT TESTED`**. §0a holds the observed state from the
2026-10-29 G1 run and supersedes the provisional verdicts in §1; the helper and trigger bodies were read on 2026-10-30
(B3b). Table list, policy names, commands and roles came from
[01-baseline-inventory.md](01-baseline-inventory.md); column detail from [03-data-model.md](03-data-model.md); verification
plan in [08-test-matrix.md](08-test-matrix.md); gates in [05-change-plan.md](05-change-plan.md). Nothing in this document has
been applied to the live project.

## 0. Evidence grade

| Claim | How it is known | Grade |
| --- | --- | --- |
| 19 tables in `public`, all individually API-disabled | Dashboard table list | Observed |
| RLS enabled on all 19, none forced, owner `postgres` | [g1-q1](evidence/g1-q1-20261029.json) | **Verified** |
| Policy names, command, role = `authenticated`, all PERMISSIVE | [g1-q2](evidence/g1-q2-20261029.json) | **Verified** |
| `USING` / `WITH CHECK` expressions | [g1-q2](evidence/g1-q2-20261029.json) | **Verified** |
| Table, column and default privileges; role membership | [g1-q6](evidence/g1-q6-20261029.json) | **Verified** |
| `EXECUTE` on the 14 definer functions | [g1-q10](evidence/g1-q10-20261029.json) | **Verified** |
| Bodies of the `private` helper functions and of the trigger functions | [g1-b3b](evidence/g1-b3b-20261029.json) | **Verified** (2026-10-30) |
| Behaviour under real requests | No authenticated test client | **Not tested** |

Two consequences follow and are repeated wherever they matter: a negative finding here is **not evidence of safety**, and
no `OK-AS-IS` verdict should be read as "verified secure" — it means "no defect is visible from the evidence collected".

## 0a. Observed state — 2026-10-29 G1 run

Grants that decide each row (from [g1-q1](evidence/g1-q1-20261029.json) and [g1-q6](evidence/g1-q6-20261029.json)):

| Role | Table privileges in `public` | Column UPDATE privileges |
| --- | --- | --- |
| `anon` | **none on any table** | none |
| `authenticated` | SELECT on 14 tables; INSERT on `webrtc_signals`; DELETE on `safe_zones` | `families`(name, settings), `profiles`(display_name), `safe_zones`(active, lat, lng, name, radius_m) |
| `service_role` | all privileges on all 19 | all columns |

Verdicts per table and verb, reading the expressions in [g1-q2](evidence/g1-q2-20261029.json) against the grants above:

| Table | SELECT | INSERT | UPDATE | DELETE |
| --- | --- | --- | --- | --- |
| audit_logs | **OK** — parent of the family only (`family_id IS NOT NULL AND is_family_parent`) | none, no grant | none, no grant | none, no grant |
| child_contact_ids | deny-all (no policy, no grant) | — | — | — |
| device_apps | **OK** — parent, or child owning the device | — | — | — |
| device_commands | **OK** — parent, or child owning the device | — | — | — |
| device_pairing_tokens | deny-all | deny-all | deny-all | deny-all |
| device_policies | **OK** — parent, or child owning the device | — | — | — |
| devices | **UNREACHABLE** — the predicate is `private.is_family_parent(family_id) OR child_user_id = auth.uid()`, but `authenticated` holds no privilege on `devices`, so no client can reach it (F6 in [00](00-status-register.md)) | — | — | — |
| families | **OK** — active member (`deleted_at IS NULL AND is_family_member`) | — | **LIVE, owner only, no transfer** — `USING` is `owner_id = auth.uid() AND deleted_at IS NULL`; `WITH CHECK` is `owner_id = auth.uid()`; `authenticated` holds column UPDATE on `name` and `settings` only, so an owner can rename and reconfigure the family but cannot change `owner_id` (F2 in [00](00-status-register.md)) | — |
| family_members | **OK** — member of the family | — | — | — |
| location_events | **OK** — parent, or child owning the device | — | — | — |
| pairing_attempts | deny-all | deny-all | deny-all | deny-all |
| pairing_requests | **OK** — child, parent, or family parent | — | — | — |
| profiles | **OK** — self (`id = auth.uid()`) or shares an active family | none, no grant | **RECOMMEND CHANGE** — `id = auth.uid()` on both sides; only `display_name` is granted, so `role` is unreachable; the trigger does not close the `'unset'` gap (F3) | — |
| remote_sessions | **OK** — parent, child, or family parent | — | — | — |
| safe_zone_states | deny-all | — | — | — |
| safe_zones | **OK** — family member | **UNREACHABLE** — the check is `private.is_family_parent(family_id)`, but `authenticated` has no INSERT grant, so no client can insert (F6) | **OK** — parent, and the new row must still be in the family; reachable through the column UPDATE grant on `active`, `lat`, `lng`, `name`, `radius_m` | **OK** — parent; DELETE grant exists |
| safety_alerts | **OK** — parent, or child owning the device | — | — | — |
| usage_daily | **OK** — parent, or child owning the device | — | — | — |
| webrtc_signals | **OK** — participant of an `accepted`/`active` session | **OK** — sender must be `auth.uid()` and a participant of an `accepted`/`active` session | — | — |

Notes on the four Realtime tables: `device_commands`, `remote_sessions`, `safety_alerts` and `webrtc_signals` each carry a
SELECT policy that scopes by family or session participant, so `postgres_changes` subscribers are filtered by a real
predicate — the load-bearing case identified in §1 is satisfied at the policy layer. Delivery itself is still untested (N4).

`families.owner_id`, `family_members.*`, `devices.*`, `safety_alerts.*` and `pairing_requests.*` are not writable by
`authenticated` at all: no UPDATE grant exists, so the absence of an UPDATE policy is not the only control.

Two policies match no grant and are therefore unreachable from a client: `devices_select_parent_or_child` (no privilege
of any kind on `devices`) and `safe_zones_insert_parent` (no INSERT). There are 15 SELECT policies and 14 tables that
carry a SELECT grant. Both are harmless today — a policy with no grant is dead, not open — but they are a drift signal: the policy set
was written against an intended grant set that no longer matches, so re-enabling a table for the Data API without reading
the grants would switch these predicated reads on by accident rather than by design (F6 in [00](00-status-register.md)).

## 1. Matrix — table × verb

"Exposure today" is **not** the same for every row. Two read paths exist independently of the Data API:

- **PostgREST:** no route to any table — every table is individually disabled while the Data API is globally enabled.
- **Realtime:** `postgres_changes` is enabled on `device_commands`, `remote_sessions`, `safety_alerts` and `webrtc_signals`. Supabase Realtime authorises a subscriber with the table's **SELECT policy**, so for those four tables the `USING` predicates are load-bearing **today**, even though PostgREST is closed. Their row in this matrix should be read as `VERIFY TODAY`, not latent.

A third possible path — `authenticated` calling the `SECURITY DEFINER` functions over `/rest/v1/rpc/*` — **was verified
closed** on 2026-10-29: [g1-q10](evidence/g1-q10-20261029.json) reports `anon_exec` and `auth_exec` false on every
app-owned function. See §Resolution.

| Table | Verb | Policy (role `authenticated`) | Exposure today | Verdict |
| --- | --- | --- | --- | --- |
| audit_logs | SELECT | `audit_logs_select_family_parent` | None — no API path | VERIFY |
| audit_logs | INSERT | — none — | None — no API path | OK-AS-IS |
| audit_logs | UPDATE | — none — | None — no API path | OK-AS-IS |
| audit_logs | DELETE | — none — | None — no API path | OK-AS-IS |
| child_contact_ids | SELECT | — none — | None — no API path | OK-AS-IS |
| child_contact_ids | INSERT | — none — | None — no API path | OK-AS-IS |
| child_contact_ids | UPDATE | — none — | None — no API path | OK-AS-IS |
| child_contact_ids | DELETE | — none — | None — no API path | OK-AS-IS |
| device_apps | SELECT | `device_apps_select_parent_or_child` | None — no API path | VERIFY |
| device_apps | INSERT | — none — | None — no API path | OK-AS-IS |
| device_apps | UPDATE | — none — | None — no API path | OK-AS-IS |
| device_apps | DELETE | — none — | None — no API path | OK-AS-IS |
| device_commands | SELECT | `device_commands_select_parent_or_child` | **Realtime live** — `postgres_changes` authorises via this policy | VERIFY |
| device_commands | INSERT | — none — | None — no API path | OK-AS-IS |
| device_commands | UPDATE | — none — | None — no API path | OK-AS-IS |
| device_commands | DELETE | — none — | None — no API path | OK-AS-IS |
| device_pairing_tokens | SELECT | — none — | None — no API path | OK-AS-IS |
| device_pairing_tokens | INSERT | — none — | None — no API path | OK-AS-IS |
| device_pairing_tokens | UPDATE | — none — | None — no API path | OK-AS-IS |
| device_pairing_tokens | DELETE | — none — | None — no API path | OK-AS-IS |
| device_policies | SELECT | `device_policies_select_parent_or_child` | None — no API path | VERIFY |
| device_policies | INSERT | — none — | None — no API path | OK-AS-IS |
| device_policies | UPDATE | — none — | None — no API path | OK-AS-IS |
| device_policies | DELETE | — none — | None — no API path | OK-AS-IS |
| devices | SELECT | `devices_select_parent_or_child` | None — no API path, and no grant | UNREACHABLE (F6) |
| devices | INSERT | — none — | None — no API path | OK-AS-IS |
| devices | UPDATE | — none — | None — no API path | OK-AS-IS |
| devices | DELETE | — none — | None — no API path | OK-AS-IS |
| families | SELECT | `families_select_members` | None — no API path | VERIFY |
| families | INSERT | — none — | None — no API path | OK-AS-IS |
| families | UPDATE | `families_update_owner` | None — no API path; live only for `name`/`settings` | LIVE — owner only (F2) |
| families | DELETE | — none — | None — no API path | OK-AS-IS |
| family_members | SELECT | `family_members_select_family` | None — no API path | VERIFY |
| family_members | INSERT | — none — | None — no API path | OK-AS-IS |
| family_members | UPDATE | — none — | None — no API path | OK-AS-IS |
| family_members | DELETE | — none — | None — no API path | OK-AS-IS |
| location_events | SELECT | `location_events_select_parent_or_child` | None — no API path | VERIFY |
| location_events | INSERT | — none — | None — no API path | OK-AS-IS |
| location_events | UPDATE | — none — | None — no API path | OK-AS-IS |
| location_events | DELETE | — none — | None — no API path | OK-AS-IS |
| pairing_attempts | SELECT | — none — | None — no API path | OK-AS-IS |
| pairing_attempts | INSERT | — none — | None — no API path | OK-AS-IS |
| pairing_attempts | UPDATE | — none — | None — no API path | OK-AS-IS |
| pairing_attempts | DELETE | — none — | None — no API path | OK-AS-IS |
| pairing_requests | SELECT | `pairing_requests_select_participants` | None — no API path | VERIFY |
| pairing_requests | INSERT | — none — | None — no API path | OK-AS-IS |
| pairing_requests | UPDATE | — none — | None — no API path | OK-AS-IS |
| pairing_requests | DELETE | — none — | None — no API path | OK-AS-IS |
| profiles | SELECT | `profiles_select_self_or_family` | None — no API path | VERIFY |
| profiles | INSERT | — none — | None — no API path | OK-AS-IS |
| profiles | UPDATE | `profiles_update_self` | None — no API path | RECOMMEND CHANGE |
| profiles | DELETE | — none — | None — no API path | OK-AS-IS |
| remote_sessions | SELECT | `remote_sessions_select_participants` | **Realtime live** — `postgres_changes` authorises via this policy | VERIFY |
| remote_sessions | INSERT | — none — | None — no API path | OK-AS-IS |
| remote_sessions | UPDATE | — none — | None — no API path | OK-AS-IS |
| remote_sessions | DELETE | — none — | None — no API path | OK-AS-IS |
| safe_zone_states | SELECT | — none — | None — no API path | OK-AS-IS |
| safe_zone_states | INSERT | — none — | None — no API path | OK-AS-IS |
| safe_zone_states | UPDATE | — none — | None — no API path | OK-AS-IS |
| safe_zone_states | DELETE | — none — | None — no API path | OK-AS-IS |
| safe_zones | SELECT | `safe_zones_select_family` | None — no API path | VERIFY |
| safe_zones | INSERT | `safe_zones_insert_parent` | None — no API path, and no grant | UNREACHABLE (F6) |
| safe_zones | UPDATE | `safe_zones_update_parent` | None — no API path | VERIFY |
| safe_zones | DELETE | `safe_zones_delete_parent` | None — no API path | VERIFY |
| safety_alerts | SELECT | `safety_alerts_select_parent_or_child` | **Realtime live** — `postgres_changes` authorises via this policy | VERIFY |
| safety_alerts | INSERT | — none — | None — no API path | OK-AS-IS |
| safety_alerts | UPDATE | — none — | None — no API path | OK-AS-IS |
| safety_alerts | DELETE | — none — | None — no API path | OK-AS-IS |
| usage_daily | SELECT | `usage_daily_select_parent_or_child` | None — no API path | VERIFY |
| usage_daily | INSERT | — none — | None — no API path | OK-AS-IS |
| usage_daily | UPDATE | — none — | None — no API path | OK-AS-IS |
| usage_daily | DELETE | — none — | None — no API path | OK-AS-IS |
| webrtc_signals | SELECT | `webrtc_signals_select_participant` | **Realtime live** — `postgres_changes` authorises via this policy | VERIFY |
| webrtc_signals | INSERT | `webrtc_signals_insert_participant` | None — no API path | VERIFY |
| webrtc_signals | UPDATE | — none — | None — no API path | OK-AS-IS |
| webrtc_signals | DELETE | — none — | None — no API path | OK-AS-IS |

Counts as first drafted, before the G1 run: **55 OK-AS-IS · 20 VERIFY · 1 RECOMMEND CHANGE** (76 cells). Every `VERIFY`
traced to one gap — predicate text not captured. That gap is now closed, so this matrix is superseded by §0a: three rows
here were resolved to `UNREACHABLE` or `LIVE` in place, and the remaining `VERIFY` rows are answered there. `OK-AS-IS` on a
write verb still means "no policy, so deny by default", not "tested".

## 2. Design intent

The shape of the policy set is coherent and, for this product, a good posture:

1. **Reads are granted, narrowly.** 21 policies exist; 15 of them are `SELECT` for role `authenticated`, most named
   `*_select_parent_or_child` or `*_select_*member*`. No policy anywhere is granted to `anon`, so an anonymous request
   has no path through RLS even if a table were exposed.
2. **Writes are mostly not granted at all.** 15 of 19 tables have no write policy in any verb. Registration, pairing,
   telemetry ingestion, command dispatch, policy sync, alert creation and audit writes therefore run through Edge
   Functions with the service role, which bypasses RLS by design. `audit_logs` follows the same shape as an audit trail
   should: one `SELECT` policy, no write policy, so it is append-only from any client's perspective.
3. **Six write policies exist, on four tables**: `profiles_update_self`, `families_update_owner`, the three
   `safe_zones_*_parent` policies, and `webrtc_signals_insert_participant`. So the statement "writes are service-role
   only" is *almost* true — these four tables are the deliberate exceptions where a signed-in user writes directly at
   the database layer, and they are exactly where the highest-value verification work sits.
4. **Four deny-all tables hold the sensitive material**: `child_contact_ids` (the child's contacts — third-party PII),
   `device_pairing_tokens` (secret material), `pairing_attempts` (rate-limit / enumeration log) and `safe_zone_states`
   (derived presence state). RLS enabled with zero policies denies `anon` and `authenticated` for all four, which is the
   correct default for secrets and attempt logs, and costs the Edge Functions nothing because they bypass RLS.

**The SELECT policies are defence-in-depth for 11 tables and live for 4.** Because each table is API-disabled, PostgREST exposes no HTTP route. But Realtime is on for four tables and authorises subscribers through these same SELECT policies, so a defective `USING` clause on `device_commands`, `remote_sessions`, `safety_alerts` or `webrtc_signals` is exploitable today by any authenticated user who subscribes. That makes the family-scoping predicate on those four the highest-priority predicate to read.

Three things make the remaining policies load-bearing:

- someone re-enables a table for the Data API (rejected in Stage 1 — see G4 in [05-change-plan.md](05-change-plan.md));
- Realtime is enabled on another table; or
- an Edge Function queries with the **caller's JWT** instead of the service role, in which case RLS applies to that
  function's reads. **Resolved by Phase E**: every one of the nine functions creates its client with `SUPABASE_URL` +
  `SUPABASE_SERVICE_ROLE_KEY`, so RLS is bypassed inside every function and no handler forwards the user JWT to the
  database ([14](14-edge-function-security-audit.md) check 12). The load-bearing cases are the first two.

## 3. Risks to verify

**Outcome after the 2026-10-29 G1 run.** The "what is missing" column below is the pre-execution wish list; every item was
collected except function bodies. Results, against [g1-q2](evidence/g1-q2-20261029.json),
[g1-q6](evidence/g1-q6-20261029.json) and [g1-q10](evidence/g1-q10-20261029.json):

- **R-01 — closed at the policy layer.** All 15 SELECT predicates scope by family membership, by device ownership
  (`devices d WHERE d.child_user_id = auth.uid()`), or by session participation. None is a bare "is authenticated". The
  one caveat is that 14 of them delegate the family test to `private.is_family_parent` / `is_family_member` /
  `shares_active_family`, and those bodies are now read and verified (R-02).
- **R-02 — closed, with a caveat.** Bodies read on 2026-10-30 ([g1-b3b](evidence/g1-b3b-20261029.json)): all three
  helpers are `SECURITY DEFINER`, owner `postgres`, `search_path = public, private, pg_temp`, no dynamic SQL, and each
  anchors on `auth.uid()` with `status = 'active'` and `families.deleted_at is null`. `authenticated` **does** hold
  EXECUTE on them — that grant is what lets a policy evaluate the helper — but `anon` does not. A policy evaluation is
  the only route to them: `private` is not an exposed schema (P20). The caveat is F8: two other `private` functions keep
  the default `PUBLIC EXECUTE`.
- **R-03 — closed at the policy layer.** `safe_zones_update_parent` carries a `WITH CHECK` identical to its `USING`
  (`private.is_family_parent(family_id)`), so a row cannot be moved into a family the caller does not parent;
  DELETE is parent-only; INSERT is unreachable (no grant). Residual: none identified for a non-parent.
- **R-04 — closed by column privilege.** `profiles_update_self` is `id = auth.uid()` on both sides, and
  `authenticated` holds column UPDATE on `display_name` only, so `role` cannot be written (F3).
- **R-05 — closed by both controls.** `WITH CHECK` is `owner_id = auth.uid()`, so even if the column were granted a
  client could not hand ownership to a different user; in practice `owner_id` is not granted at all. The cost is that
  there is no owner-transfer feature at the database layer (F2).
- **R-06 — closed at the policy layer.** `webrtc_signals_insert_participant` requires `from_user_id = auth.uid()` **and**
  an `accepted`/`active` session in which the caller is parent or child. The payload-size concern is untouched.
- **R-07 — closed for the client roles.** `anon` holds no privilege on any table; RLS is on for all 19 and forced for
  none. The residual is custody of the `service_role` key, which bypasses RLS by design ([06](06-secrets-and-environments.md)).
- **R-08 — closed.** Q3b found exactly one non-internal trigger on `auth.users`, and the body is now read: it inserts
  `profiles(id, role, display_name)` with `role` hard-coded to `'unset'`, `on conflict (id) do nothing`, and derives
  `display_name` from signup metadata or the email local-part, truncated to 60 characters. Signup metadata cannot set
  the role ([g1-b3b](evidence/g1-b3b-20261029.json)).

| # | Risk | Why it matters here | What is missing |
| --- | --- | --- | --- |
| R-01 | `*_select_parent_or_child` predicates may not scope by family | Cross-family leakage is the top risk in a parental-safety product: one parent reading another family's children's location, contacts or alerts. A predicate that only asserts `auth.uid() is not null`, or joins `devices` without a `family_id` filter, passes the dashboard review and fails the threat model. | `qual` for all 15 SELECT policies |
| R-02 | Predicates may call a helper `SECURITY DEFINER` function | Supabase's common idiom is `is_family_member(family_id)`. If it is `SECURITY DEFINER` without a pinned `search_path`, it is hijackable; if it is owned by a table owner and RLS is not forced, it can read rows the caller could not. | Function list, `prosecdef`, `proconfig`, owner, `EXECUTE` grants |
| R-03 | `safe_zones` INSERT/UPDATE/DELETE may be usable by a non-parent family member | The names say "parent" but the name is not the predicate. A child account that can insert or delete a safe zone is a safety-control bypass, not a cosmetic bug. `UPDATE` additionally needs a `WITH CHECK`, otherwise a row's `family_id`/device binding could be moved to another family. | `qual` and `with_check` for the three policies |
| R-04 | `profiles_update_self` may allow privilege escalation through the `role` column | The `profiles` table comment says `role` is set once by an Edge Function — but a table comment enforces nothing. If the policy is row-level only, a signed-in user can set their own `role` to `parent` (and possibly rewrite other self columns). Enforcement must be a column-level `UPDATE` privilege revocation or a `BEFORE UPDATE` trigger. | Answered 2026-10-29 — see outcome below |
| R-05 | `families_update_owner` may permit owner transfer to an arbitrary user | Owner transfer is the highest-privilege mutation in the schema. Without a `WITH CHECK` that the new owner is a member of that family, a family owner could hand ownership to an unrelated account, or an attacker who obtains one owner session could entrench. | Answered 2026-10-29 — see outcome below |
| R-06 | `webrtc_signals_insert_participant` may not bind the row to a session the caller participates in | `webrtc_signals` holds 1,093 rows and is one of four Realtime-enabled tables. If the check only requires authentication, any signed-in user could inject signalling payloads into another family's session. | `with_check`, FK to `remote_sessions` |
| R-07 | Table/column grants may be broader than the policy set assumes | RLS-without-policy only denies if the role still reaches the table and RLS is actually on. Any table where RLS is off, or where `anon` retains `SELECT`, is exposed the moment the Data API toggle flips. Also `service_role` keys must never reach a client — see [06-secrets-and-environments.md](06-secrets-and-environments.md). | `role_table_grants`, `pg_class.relrowsecurity`, `relforcerowsecurity` |
| R-08 | The `auth.users` insert trigger that creates `profiles` rows is unaudited | Baseline §2 records that profile rows are created by an `auth.users` trigger. If that function is `SECURITY DEFINER` with a mutable `search_path`, signup is an injection surface, and if it derives the role incorrectly it undermines R-04. | Trigger definitions, function body, `prosecdef` |

## 4. Least-privilege recommendations

Every item is `PROPOSED — NOT APPLIED` and none disables RLS or widens access. The `Gated on` column names the query that
supplies the evidence; those queries ran on 2026-10-29, so it is a provenance column now, not an open gate. Post-G1 status
of the proposals:

- **P-01 — not needed as written.** All 15 predicates already scope by family, device ownership or session
  participation (§3). Keep only the consistency argument for a shared helper.
- **P-02 — satisfied except one path.** `EXECUTE` is already owner + `service_role` only, and `PUBLIC` was stripped at
  creation ([g1-q10](evidence/g1-q10-20261029.json)). All 38 functions pin a `search_path`; the only deviation is
  `private.remote_session_transition_guard`, which omits `private` (F8). No body-level `set_config` was found.
- **P-03 — enforcement exists; harden it.** The column grant already excludes `role`, and a `profiles_before_update`
  trigger is present. The body is read: it rejects `id` and `role` changes only when `old.role <> 'unset'`, so the
  trigger does not protect an unassigned profile (F3).
- **P-04 — the `WITH CHECK` half is already in place.** `safe_zones_update_parent` re-evaluates
  `is_family_parent(family_id)` on the new row, so a zone cannot be moved into another family. Only the immutability
  suggestion is outstanding.
- **P-06 — superseded.** `families_update_owner` already carries `WITH CHECK (owner_id = auth.uid())`, which blocks
  transfer to any other user. Nothing further is needed for R-05.

| # | Proposal | Justification | Gated on |
| --- | --- | --- | --- |
| P-01 | Re-express each of the 15 SELECT predicates as an explicit membership test against `family_members` for the row's family, and make the default deny (no predicate that merely checks "is authenticated") | Removes R-01 at the source; a shared helper keeps the 15 policies consistent instead of 15 chances to drift | Q2, Q7, Q8 |
| P-02 | Pin `search_path` on every `SECURITY DEFINER` function, revoke `EXECUTE` from `PUBLIC`/`anon`, grant only what the policy needs, and keep the owner non-superuser | Standard hardening for R-02 and R-08; costs nothing functionally | Q1, Q7 |
| P-03 | Revoke column `UPDATE` on `profiles.role` from `anon`/`authenticated` and add a `BEFORE UPDATE` trigger that rejects any change to `role` unless the caller is the service role | The only enforcement that matches the stated design in the table comment (R-04); row-level policy alone cannot protect one column | Q3, Q6, Q8 |
| P-04 | Add an explicit `WITH CHECK` to `safe_zones_update_parent`, and make `family_id` / device ownership immutable via trigger or constraint | Prevents a checked row from being rewritten into another family, and prevents a child account from using a parent-only verb through a crafted payload (R-03) | Q2, Q8 |
| P-05 | Restrict `webrtc_signals` INSERT to rows whose `remote_session` the caller participates in, and cap payload size at the column level | Signalling is the one live, high-volume path a client writes; scoping it by session is the minimum (R-06) | Q2, Q8 |
| P-06 | ~~Add `WITH CHECK` to `families_update_owner` asserting the new owner is an existing member of that same family~~ | Superseded: the policy already has `WITH CHECK (owner_id = auth.uid())`, and `owner_id` is not granted to clients. No transfer path exists (R-05) | answered, Q2 + Q6 |
| P-07 | Keep all 19 tables API-disabled; if a table is ever exposed, write policies for every verb **before** the toggle, not after | Preserves the current defence-in-depth and avoids "temporarily exposed" windows | Q6 |
| P-08 | Capture the policy set into a tracked baseline migration and review it as code | The schema has no migration history (G3), so today the policies are only editable in a dashboard — the most likely way to lose P-01…P-06 | Q2, Q7 |

Deferred, deliberately: forcing RLS (`relforcerowsecurity`) on the four deny-all tables. It would also constrain
`SECURITY DEFINER` functions owned by a table owner, so it must wait until P-02's ownership map exists.

## 5. Policy text — captured, with the bodies now read

The pre-G1 wish list, for provenance. Everything below was captured on 2026-10-29; the `prosrc` bodies that the approved
query set excluded were read on 2026-10-30 (B3b, closed). "Audit complete" now means bodies read.

- **All 15 SELECT predicates** — `qual` exactly as stored, for: `audit_logs_select_family_parent`,
  `device_apps_select_parent_or_child`, `device_commands_select_parent_or_child`,
  `device_policies_select_parent_or_child`, `devices_select_parent_or_child`, `families_select_members`,
  `family_members_select_family`, `location_events_select_parent_or_child`,
  `pairing_requests_select_participants`, `profiles_select_self_or_family`,
  `remote_sessions_select_participants`, `safe_zones_select_family`, `safety_alerts_select_parent_or_child`,
  `usage_daily_select_parent_or_child`, `webrtc_signals_select_participant`.
- **All 6 write predicates** — `qual` *and* `with_check`. The command decides which expression exists: an INSERT policy has no `USING`, so its `qual` is NULL by design and `with_check` is its only expression; SELECT and DELETE policies carry `qual` alone and reject `WITH CHECK`; UPDATE uses `USING` for visible rows and reuses it for new rows when `WITH CHECK` is null. A null check is therefore not itself a defect — the findings are a NULL `qual` on a **PERMISSIVE** SELECT/DELETE/UPDATE policy (a NULL on a RESTRICTIVE policy restricts nothing and must be read together with its siblings), a NULL `with_check` on an INSERT policy, and a `WITH CHECK` *weaker than, or disagreeing with,* its `USING` clause:
  `profiles_update_self`, `families_update_owner`, `safe_zones_insert_parent`, `safe_zones_update_parent`,
  `safe_zones_delete_parent`, `webrtc_signals_insert_participant`; for `safe_zones_update_parent` record null explicitly.
- **Per policy**: `permissive` (PERMISSIVE vs RESTRICTIVE), `roles` array, `cmd` — the dashboard showed only name/command/role.
- **Helper function bodies** (Q7): every function referenced by a predicate, plus its `prosecdef`, `proconfig`,
  owner and `EXECUTE` grants.
- **The `auth.users` insert trigger function** (Q3b, Q7): full body, `prosecdef`, `search_path`, and how `role` is
  derived at signup.
- **Column-level `UPDATE` grants on `profiles`** (Q6) — the specific evidence for R-04.
- **`relrowsecurity` and `relforcerowsecurity` for all 19 tables** (Q1) — captured: all enabled, none forced, owner
  `postgres` on every table.

---

## Update — second read-only pass (2026-10-29, historical)

Written before the G1 run, kept as written because it frames the RPC question. Both points are resolved in §Resolution:
the RPC route is closed, and the helper bodies were unread at the time — they were read in B3b on 2026-10-30 (§Resolution
records that result). Neither closed a row in the matrix at the time.

1. **`profiles_before_update` trigger exists** (BEFORE UPDATE, row-level) on `profiles`, which is the likely guard against `role` self-escalation via `profiles_update_self`. Presence is observed; behaviour is **NOT VERIFIED** — the body is only readable with SQL access. *(Superseded 2026-10-30: the body was read in B3b. It checks `old.role <> 'unset'`, so the `'unset'` bootstrap value bypasses the role guard; `id` is immutable and `updated_at` is maintained. See F3.)* The `profiles_update_self` row is already `RECOMMEND CHANGE` (column-level grant restriction), and that verdict is unchanged: the trigger is corroborating evidence, not proof.
2. **All 14 Postgres functions are `SECURITY DEFINER`.** Five of them take **no actor parameter at all** — `poll_device_commands(p_device_id)`, `replace_device_apps(p_device_id, p_family_id, p_apps)`, `expire_stale_commands(p_device_id)`, `detect_offline_devices()`, `expire_stale_sessions()` — so for those, "the caller passes a verified actor" is not even possible; everything depends on the `EXECUTE` grant and on the body's own scoping. The other nine take an actor argument (`p_actor…`, `p_owner`, `p_child_user_id`), and the requirement is that the body take the caller's identity from `auth.uid()` — the setting PostgREST derives from the verified JWT — ignore or equals-check the argument, authorise any cross-user case explicitly, and reject a NULL `auth.uid()`.

**New top risk — RPC exposure.** Per-table Data API exposure is disabled, but the Data API itself is enabled, and every function sits in `public`. If `anon` or `authenticated` retain the default `EXECUTE` grant — and `public` is an exposed schema, which Q10 reports as `schema_usage` — these functions are reachable at `/rest/v1/rpc/<name>` regardless of table exposure. That would put pairing, revocation, policy application, command polling and remote-session creation behind a direct HTTP call whose only guard is the function body. The five actor-less functions are the worst case: a `device_id` is the only argument, so a wrong grant becomes a cross-family read/write primitive keyed on a guessable identifier.

It cannot be answered from the dashboard. The decisive evidence is:

```sql
-- read-only; run per 08-test-matrix.md §0 Q6/Q7
select p.proname, p.prosecdef, p.proconfig, pg_get_userbyid(p.proowner) as owner,
       has_function_privilege('anon', p.oid, 'EXECUTE') as anon_exec,
       has_function_privilege('authenticated', p.oid, 'EXECUTE') as auth_exec
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.prokind = 'f'
order by p.proname;
```

`anon_exec` must be false everywhere; `auth_exec` matters just as much, because every parent and child account is `authenticated`. Until both are known — and, for the five actor-less functions, the body has been read — no verdict of PASS is possible for authorisation, and the matrix's "Exposure today" column must be read as **"Realtime-open on 4 tables; no PostgREST table route; RPC exposure unverified"**.

---

## Resolution — G1 run (2026-10-29)

The paragraph above is kept as written because it states why the question mattered. It is now answered.

**RPC exposure: not present.** [g1-q10](evidence/g1-q10-20261029.json) returns `schema_usage` true for both `anon` and `authenticated` on `public`, but `anon_exec = false` and `auth_exec = false` for **all 14** app-owned functions. Every one carries a non-null `proacl` of `postgres=X/postgres,service_role=X/postgres`, so the implicit `PUBLIC EXECUTE` was removed at creation; only the owner and the service role can call them. The five actor-less functions are therefore not reachable at `/rest/v1/rpc/*`, and the body-reading that was conditional on a positive grant is no longer a prerequisite for this verdict.

**`profiles_before_update`: read, and weaker than it looks.** [g1-q6](evidence/g1-q6-20261029.json) shows `authenticated` holds column-level UPDATE on `profiles.display_name` only. A client `update profiles set role = …` fails on column privilege before the policy or the trigger is evaluated. The body ([g1-b3b](evidence/g1-b3b-20261029.json)) rejects `id` and `role` changes — but only when `old.role <> 'unset'`, so every account that has not yet been assigned a role passes the trigger untouched. The column grant is the only control; the trigger is not a second line (F3).

**Scope of the resolution.** The bodies of the `private` helper functions (`is_family_parent`, `is_family_member`, `shares_active_family`, `handle_new_user`) and of the five trigger functions were not selected by Q3/Q7/Q10. They were read on 2026-10-30 — see the section below.

The matrix column "Exposure today" should now be read as **"Realtime-open on 4 tables; no PostgREST table route; RPC closed to client roles"**.

---

## Resolution — B3b read-only pass (2026-10-30)

[g1-b3b](evidence/g1-b3b-20261029.json) read the bodies. Three things came back that the register did not previously state:

1. **The `private` schema holds 24 functions, not five.** Thirteen of the 14 RPC functions in `public` have near-identical twins in
   `private`; `public.request_remote_session` has no private twin, and 11 `private` functions have no public twin
   (`record_audit` plus 10 helpers/triggers).
   `public.request_device_recovery` is a one-line wrapper around `private.request_device_recovery`, so the logic lives in
   `private` — a `public`-only baseline would capture 14 wrappers and none of the implementation. This is a G3 input.
2. **Two `private` functions keep the default `PUBLIC EXECUTE`** — `request_device_recovery` and
   `remote_session_transition_guard` — and the guard also omits `private` from its `search_path`. Latent, not live:
   `private` is not an exposed schema and `anon` has no `USAGE` on it (F8).
3. **Identity comes from an argument, not from `auth.uid()`** in the actor-taking implementations. The recovery function
   accepts any active parent of the device's family as actor; `public.request_remote_session` does not check the parent
   at all. The `public` wrapper is `service_role`-only; the `private` recovery implementation still carries `PUBLIC`
   EXECUTE (F8), but `private` is not an exposed schema. The control is the caller, not the database (F7).

The helpers themselves are clean: every one anchors on `auth.uid()`, requires active membership and a non-deleted
family, uses fully-qualified names, and contains no dynamic SQL. **No policy row in the matrix changes verdict as a
result of this pass.**

The "Exposure today" column should now be read as **"Realtime-open on 4 tables; no PostgREST table route; RPC closed to
client roles; `private` not an exposed schema"**.
