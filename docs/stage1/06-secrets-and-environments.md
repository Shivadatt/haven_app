# 06 — Secrets and environments

Scope: how each credential in this stack is stored, who rotates it, what differs per environment, and what to do when one leaks.
Inputs: [01-baseline-inventory.md](01-baseline-inventory.md) (live read-only discovery, 2026-10-29), [02-architecture.md](02-architecture.md), [04-rls-matrix.md](04-rls-matrix.md), [05-change-plan.md](05-change-plan.md).

**No secret value appears in this document, and no secret value was read from this machine.** No Supabase access token and no database password was ever created, exported or stored: G1 was answered on 2026-10-29 through the dashboard SQL Editor instead. No Firebase project belongs to this product (gate G2). The inventory below is therefore *prospective*: it states where each secret must live once it exists, not where one was found.

## 1. Secret inventory

Placement codes: **L** = local `.env` (git-ignored) · **S** = Edge Function secret (`supabase secrets set`) · **C** = CI secret store · **K** = password manager / operator shell only · **A** = Android client build · **R** = may be committed (public by design).

| Secret | May live | Must never live | Rotation owner | Rotation trigger |
| --- | --- | --- | --- | --- |
| `SUPABASE_URL` (public: `https://hhqgreaoqulmfwfwarhc.supabase.co`) | R, L, C, A, S | — (not a credential) | Project owner | Project moved, recreated or region changed |
| `SUPABASE_ANON_KEY` | L, C, A, S | Never treated as an authorization boundary; never in `config.toml`; never used from a server as a privileged path | Project owner | Abuse or egress anomaly, planned key rotation, or legacy-JWT-secret rotation |
| `SUPABASE_SERVICE_ROLE_KEY` | S, C (deploy step only) | Repo, `.env.example`, `config.toml`, APK, CI logs, chat, screenshots, function `console.log` | Project owner | Any exposure; operator/device change; before public launch as hygiene |
| DB password (`postgres`) | K, operator shell env `SUPABASE_DB_PASSWORD` | Repo, migrations, `config.toml`, CI logs, chat | Project owner | After first direct-connection use (G3 dump), any exposure, operator change |
| Supabase access token (`sbp_…`, CLI) | K, operator shell env `SUPABASE_ACCESS_TOKEN`, C (minimal scope) | Repo, `.env.example`, committed scripts, shell history in shared machines | Project owner | Any exposure; offboarding; 90-day hygiene |
| Firebase client config (project id, app id, API key, sender id) | R, L, C, A, S (project id only) | Never used as a server credential; never in Edge Function secrets except the non-secret project id | Project owner | Firebase project change (gate G2), API-key restriction change |
| Firebase Admin service-account JSON | S only (future FCM) | Repo (blocked by `.gitignore` `service-account*.json` and `*-firebase-adminsdk-*.json`), APK, `config.toml`, chat, logs | Project owner | G2 project creation, any exposure, 90-day key hygiene, operator change |
| FCM server key / legacy credential (`AAAA…`) | S (only if a legacy sender is unavoidable) | Repo, APK, `config.toml`, chat | Project owner | Any exposure, or migration to service-account auth (preferred) |
| Future TURN credentials (static user/pass or provider secret) | S (to mint short-lived credentials), K (provider console) | APK, repo, client-side logs | Project owner | Any exposure, provider rotation, TTL policy change |

Notes that change the blast radius:

- Exposing the **anon key is not an incident** in the current posture. All 19 tables are individually API-disabled and writes are service-role only ([01](01-baseline-inventory.md) §2), so the key unlocks only `auth` and the 9 Edge Functions. Treat a leak as abuse-monitoring, not containment.
- There is a **single owner** for every row: the one account that owns org `symqztrmaziuwdibcfrq`. No separate security owner, no second approver and no break-glass account is recorded — a real gap, not a documentation omission.
- Rotating a *legacy JWT secret* is not a per-key rotation: it invalidates the anon key, the service-role key and every issued user token at once, forcing all 10 MAU to sign in again. Whether this project still uses legacy JWT keys or the newer independent API keys is **NOT VERIFIED** — Q1–Q10 read the database catalogue, not the API settings page, so this needs a one-line check of Project Settings → API.

## 2. Placement rules for this stack

| Placement | Holds | Rule | Verified state |
| --- | --- | --- | --- |
| `.env` (local) | Client-safe values only: URL, anon key, Firebase client ids | Git-ignored; created by copying `.env.example`; never contains service-role, DB password, service-account JSON | `.gitignore` ignores `.env` and `.env.*` with `!.env.example` — present. Repo has **zero commits**, so the rule is configured but has never been exercised by a commit |
| `.env.example` | Names and non-secret defaults | Placeholders only; server-side names stay commented out | Present; server-side entries are commented (`# SUPABASE_SERVICE_ROLE_KEY=`, `# FCM_SERVICE_ACCOUNT_JSON=`) |
| Edge Function secrets | Service-role key, FCM service account, future TURN secret | Set with `supabase secrets set --env-file <git-ignored file>`; values never enter the repo; read in code via `Deno.env.get` and never logged | Requires a linked project — **not performed** |
| `supabase/config.toml` | Local CLI configuration | No literal secrets. `env(VAR)` substitution is for local runs only. `[edge_runtime.secrets]` is commented out and must stay that way | No secret present in the file as read |
| CI secret store | Deploy-time `SUPABASE_ACCESS_TOKEN`, service-role key for function deploys | Separate secret per environment; never echoed; masked in logs | **No pipeline exists** (`.github/` absent, no commits) — this row is a proposal, not current state |
| Android `google-services.json` | Firebase client config | Client config, **never a server secret** — it ships inside the APK by design. Generated per build flavor from the matching Firebase project. Currently git-ignored, which is stricter than required; committing it is a policy decision, not a safety one | Ignored by `.gitignore` line 10. No app module exists yet |
| `service-account*.json` | Firebase Admin key | Must never be committed, never bundled into an app, never shared over chat | Blocked by `.gitignore` lines 9–10, which also cover the real `*-firebase-adminsdk-*.json` filename |

Forward-looking rules, because `supabase/functions/` does not exist yet (no Edge Function source is in the repository):

- No `console.log`/`console.error` of an env value, request header or full request body in an Edge Function; log an identifier, not a credential.
- Migration files are schema only. Seed data must never carry a token, password or service-account blob.
- Any new secret gets a row in §1 before it is created, not after.

## 3. Environment strategy

Only **one** environment exists. Nothing else may be assumed.

| Environment | Exists | Supabase | Firebase | Data |
| --- | --- | --- | --- | --- |
| `prod` | Yes | `parent-control-prod` / `hhqgreaoqulmfwfwarhc`, ap-northeast-2, Free/NANO, no tracked migrations | None for this product (G2) | 19 tables, 8 profiles, 1,773 location events, 39 remote sessions, 10 MAU |
| `dev` | **No** | — | — | — |
| `staging` | **No** | — | — | — |

`prod` already holds development-shaped data. That is an argument for creating `dev`, not evidence that one exists ([05](05-change-plan.md) G6).

Creating `dev` and `staging` would require, in this order:

1. **A decision and an owner.** Two more hosted projects mean two more surfaces with credentials, quotas and (eventually) data. This is an approval item, not an implementation detail.
2. **A baseline migration first (G3).** Without a captured baseline, a new project cannot be built to match `prod`; a fresh project would be guesswork.
3. **No data copy.** Family, device and location rows belong to real users. Seeding `dev` with `prod` data would multiply the exposure of the most sensitive tables. Synthetic seed data only.
4. **Budget check.** Whether the org has a free project slot left was not inspected; a second paid project is a cost decision and must not be enabled silently. Compare with the cost posture in [07-ops-and-observability.md](07-ops-and-observability.md) §6.
5. **FCM implications (compounds G2).** Each environment needs its own Firebase project, own `google-services.json` and own service account, or one project with distinct Android application ids per environment. That forces either distinct `applicationId` suffixes — which changes the installed package, a user-visible decision — or per-flavor config wiring. Do not guess the package name; no app is registered yet.

| Variable | prod | dev (does not exist) | staging (does not exist) | Must differ per env? |
| --- | --- | --- | --- | --- |
| `APP_ENV` / build flavor | `prod` | `dev` | `staging` | Yes |
| `SUPABASE_URL` | Project `hhqgreaoqulmfwfwarhc` | Own project | Own project | Yes |
| `SUPABASE_ANON_KEY` | prod value | dev value | staging value | Yes |
| `SUPABASE_SERVICE_ROLE_KEY` | prod secret | dev secret | staging secret | Yes — never share |
| `SUPABASE_DB_PASSWORD` | prod value | dev value | staging value | Yes |
| `FIREBASE_PROJECT_ID` | (none yet) | own id | own id | Yes |
| `google-services.json` source | prod flavor | dev flavor | staging flavor | Yes |
| `FCM_SERVICE_ACCOUNT_JSON` | (none yet) | own key | own key | Yes |
| `TURN_URL` / TURN secret | (none yet) | dev | staging | Yes |
| Android `applicationId` | release id | debug/suffix id | test/suffix id | Yes — build config, not an env var |
| `SUPABASE_ACCESS_TOKEN` | operator-scoped | same operator token | same operator token | No — per operator, never per environment |

## 4. If a secret is exposed

Sequence: contain (≤15 min) → rotate (≤1 h) → verify (≤24 h) → record. Never "wait and see", and never rotate by disabling RLS or API exposure.

| Secret | Blast radius | Rotation steps | Verify in |
| --- | --- | --- | --- |
| Service-role key | Full read/write on all 19 tables, bypasses RLS; can forge any family's data | Issue replacement key in project settings, update Edge Function secrets, redeploy the 9 functions, invalidate the old key | Function logs for 4xx/5xx after redeploy; `audit_logs`; row deltas in `devices`, `profiles`, `location_events` |
| DB password | Direct SQL as `postgres`: dump everything, alter policies, drop tables | Reset password in Database settings, update the operator shell only, re-link | Connection/auth errors in database logs; schema drift via `db diff` (needs a link) |
| Access token (`sbp_`) | Management API: read project config, trigger deploys, create resources | Revoke in Account → Access Tokens, issue a new scoped token | Project audit/activity list; unexpected deploys |
| Anon key | Minimal — Data API tables are all disabled; unlocks `auth` and the 9 functions | Rotate only if abuse is observed; otherwise monitor | Egress counter, function invocation volume, auth rate limits |
| Firebase Admin service account | Push notifications to every install; token minting for the Firebase project | Delete the key in Google Cloud IAM, create a new one, update the Edge Function secret, redeploy | Firebase/Cloud audit logs; FCM send failures |
| FCM legacy server key | Same as above, weaker controls | Delete in Firebase console, migrate to service account | Same |
| TURN secret | Relay abuse at your cost; traffic metadata | Rotate at provider, update secret, shorten credential TTL | TURN provider usage/billing |
| Any operator credential used for G3 or function export | Temporary elevation to full control | Rotate immediately after the task finishes; none was used for G1 | As above |

What to check after any exposure (all read-only, all require access this machine does not have):

- Edge Function logs for the exposure window: unexpected invocations, new client IPs/user agents, 401/403 spikes.
- Auth logs: new sessions, sign-ins from unfamiliar locations, password changes. All OAuth/phone providers are disabled, so the surface is email only.
- `audit_logs` (262 rows, parent-only SELECT): new rows you did not cause.
- `pairing_attempts` (68 rows): a burst would indicate pairing abuse rather than key theft, but it is the cheapest tamper signal available.
- Quota deltas on the dashboard: egress (0.12/5 GB), DB size (32/500 MB), log query (33.9/100 GB). A jump with no product activity is the strongest available signal.
- Caveat: investigating consumes the same log-query quota that is already the tightest limit — see [07](07-ops-and-observability.md) §2.

## 5. Verification checklist (presence only)

Never print a value. These check existence and placement, nothing else.

```bash
# 1. Presence only — prints "set" or "MISSING", never the value
for v in SUPABASE_ACCESS_TOKEN SUPABASE_DB_PASSWORD SUPABASE_SERVICE_ROLE_KEY; do
  if [ -n "${!v-}" ]; then echo "$v: set"; else echo "$v: MISSING"; fi
done

# 2. The file that must never be committed is ignored (prints the matching rule)
git check-ignore -v .env service-account-prod.json google-services.json

# 3. No tracked file mentions a token-shaped string — file names only, no content
#    (requires at least one commit; the repo currently has zero)
git grep -lE 'sbp_[A-Za-z0-9]{20,}|sb_secret_|service_role"|BEGIN PRIVATE KEY' -- . ':!docs/'

# 4. Secret names on the hosted project (names and digests only; needs a link)
supabase secrets list

# 5. Working tree is clean of ignored artifacts before a commit
git status --short --ignored | grep -E '^!!' || echo "no ignored files present"
```

Rules for the checklist itself: no `echo $SECRET`, no `env | grep`, no `--debug` on `supabase` commands, no pasting terminal output into chat or tickets, and `supabase secrets list` output is safe to share (it shows a digest, not a value). A green checklist proves *placement*, never *non-exposure* — only log review in §4 can suggest that, and even that is not proof.
