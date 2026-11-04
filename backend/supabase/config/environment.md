# `backend/supabase/config` — runtime configuration, NAMES ONLY

Nothing in this directory holds a value. A secret value here would be a repository secret, and
the standing rule is absolute: **no credential, key, token, or private value in any file, report,
screenshot, or terminal output.** This page lists the names the Edge Functions read, who reads
them, what happens when each is missing, and how an operator supplies one.

TARGET PROJECT: Supabase `parent-control-staging` / `dzonzgngwxclhfnvxtvu` — **staging only**.
Production `parent-control-prod` / `hhqgreaoqulmfwfwarhc` is never a target of this lane.

## 1. The complete set, as read by the code

The list below was produced by scanning every `Deno.env.get` call in `backend/supabase/functions/`
(6 names, 7 call sites), not from a specification document. A name that appears in a design note
but is read by nothing is marked as such — inventing a required secret is as bad as inventing a
column.

| Name | Read by | Kind | If absent | Status for staging |
|---|---|---|---|---|
| `SUPABASE_URL` | `_shared/auth.ts` (getServiceClient), `cron/index.ts` | project URL — public, not a credential | `503 server_misconfigured` | required at deploy time; value is the dashboard's own API URL for `dzonzgngwxclhfnvxtvu` |
| `SUPABASE_SERVICE_ROLE_KEY` | `_shared/auth.ts` (getServiceClient), `cron/index.ts` | **secret** | `503 server_misconfigured`, never a fallback client | **NOT CREATED** — A9 is unsigned; see §3 |
| `SUPABASE_ANON_KEY` | no Edge Function reads it | client key | n/a | set in the app's own build config, not here; never used as a server authority (14 §anon) |
| `PAIRING_HASH_PEPPER` | `_shared/validation.ts` (identifierHash) | **secret** | silent degrade to plain SHA-256 + one `pairing_hash_pepper_missing` warning per isolate — finding E6, preserved not fixed | **NOT CREATED** — A9 |
| `CRON_SECRET` | `cron/index.ts` | **shared secret** | `503 cron_not_configured`; a configured value shorter than 16 characters is refused the same way | **NOT CREATED** — A9 |
| `TURN_SECRET` | `remote-session/media.ts` (mintTurnCredential) | **secret** (HMAC key) | `ice` returns `503 server_misconfigured` | **NOT CREATED** — A9; and the NAME is inferred, see §2 |
| `TURN_HOST` | `remote-session/media.ts` | hostname, not a credential | same `503` on the `ice` action | required at deploy time; NAME inferred, see §2 |

## 2. Which names are evidenced and which are inferred

The deployed bundles were never readable (`docs/stage1/13-edge-function-source-inventory.md`), and
the capture records no secret inventory for them. Consequences, stated plainly:

* `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are the Supabase Edge conventions and are used by
  every function; a wrong name degrades to `503 server_misconfigured`, never to open access.
* `TURN_HOST` / `TURN_SECRET` — **the names are not captured anywhere.** They are conventional and
  are referenced by name only in `remote-session/media.ts`. Confirm against the dashboard Secrets
  list before any deploy; if the deployed function reads a different name, this lane is wrong.
* `STUN_URL` / `TURN_URL` appear in `docs/stage1/06-secrets-and-environments.md:78` as an operator
  expectation. **No code in this lane reads them**, and `ice` returns TURN entries built from
  `TURN_HOST` plus two transport forms. Do not create them and assume the functions use them.

## 3. How an operator supplies a value (browser only)

Supabase dashboard → project `parent-control-staging` → **Configuration → Secrets** (Edge
Functions). Add by name; the dashboard stores the value and shows only a masked entry. Then
**Configuration → API Keys** for the `SUPABASE_*` pair. Nothing else in this project's approved
workflow touches them: no CLI, no REST, no `.env` file, no `supabase secrets set`.

Order of dependence, from `docs/stage2/functions/DEPLOYMENT-MAP.md` §1: the schema (A3) must land
before a secret is worth creating, because every function contacts a table before it contacts the
Auth server, and staging currently holds 0 tables. Creating a secret into a project with no schema
would test nothing.

## 4. Rules that do not relax

1. No value in a file, commit, report, screenshot, log line, or chat message.
2. No value in the Flutter app or the child agent APK. `SUPABASE_SERVICE_ROLE_KEY` in a mobile
   binary is a total break of the RLS model; the app is built with the anon key only.
3. A secret is not "created" by this repository. A9 (`docs/stage2/approval-package-v3-implementation-instruments.md`)
   is `STATUS: UNSIGNED`, and every row above marked NOT CREATED stays that way until the owner
   signs it and performs the dashboard write themselves.
4. `identifierHash`'s E6 fallback and `cron`'s short-secret refusal are deliberate fail-closed
   branches; do not "improve" them into defaults.

Related: [../functions/README.md](../functions/README.md) · [../tests/README.md](../tests/README.md)
