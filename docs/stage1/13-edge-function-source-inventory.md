# 13 — Edge Function source inventory

Status: **`PARTIAL — SOURCE CAPTURED, REVIEWED READ-ONLY; NO LIVE REQUEST RUN`**.
Phase E. Captured 2026-10-30 from the deployed project `parent-control-prod` (`hhqgreaoqulmfwfwarhc`).

Evidence base: [evidence/edge-functions/capture-20261030.json](evidence/edge-functions/capture-20261030.json).
Companion documents: [14-edge-function-security-audit.md](14-edge-function-security-audit.md),
[15-edge-function-test-plan.md](15-edge-function-test-plan.md), [16-phase-e-findings.md](16-phase-e-findings.md).

Label key: **VERIFIED** (read in the deployed source), **INFERRED** (follows from what was read but a step was not
observed), **NOT VERIFIED**, **NOT TESTED** (no request was made), **PROPOSED — NOT APPLIED**.

This document is an inventory. Security verdicts live in 14; findings with remediation live in 16.

## 1. Repository state — the source is not in the repository

| Path | Present | Meaning |
| --- | --- | --- |
| `supabase/config.toml` | yes | CLI configuration only |
| `supabase/functions/` | **no** | no function source, no `index.ts`, no `_shared/` |
| `supabase/functions/*/deno.json` or import map | **no** | — |
| `supabase/.temp/`, `.branches/` | no | project never linked from this checkout (both are gitignored anyway) |

**VERIFIED (local filesystem, 2026-10-30).** The repository contains no Edge Function source in any form. The deployed
code is therefore the only copy of record, and it was read from the dashboard.

`supabase/config.toml` is also **not** a description of production: it declares local `[api] schemas = ["public",
"graphql_public"]`, while the deployed project exposes `public` and `extensions` and offers `private`
([g1-b3b](../stage1/evidence/g1-b3b-20261029.json) `data_api_exposure`). Any future `supabase db diff` or local
`supabase start` therefore does not reproduce production exposure. This is recorded as a documentation drift note, not
as a finding against the deployed system.

## 2. How the source was obtained

Method: navigate to `/dashboard/project/<ref>/functions/<slug>/code`, wait for the `FILES` tree, then read the Monaco
model text in the page with `window.monaco.editor.getModels()[0].getValue()` and compute SHA-256 in the page over that
exact string. For `pairing` and `auth-bootstrap`, each `_shared/*.ts` entry was selected in the file tree and read the
same way.

Explicitly **not** done, per the Phase E restrictions:

- no browser cookie, `localStorage`, session token or credential was read;
- no ZIP export and no `supabase login` / `link` / `functions download`;
- no function was edited, redeployed, invoked or log-queried;
- no SQL was executed; no `GRANT`, `REVOKE`, `ALTER FUNCTION` or setting change.

Consequences of that method: the text is exactly what the editor serves, but per-file line numbers only exist for the two
readable functions and the six shared modules. The seven bundles are 2-line esbuild output with identifiers minified and
all imports inlined; they were reviewed by identifier and by decompiled structure, not by line. No source maps are
served, so original file boundaries inside those bundles are **NOT VERIFIED**.

## 3. Function inventory

| # | Function | Source form | Chars | Lines | Actions | Identity model |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `pairing` | readable TS | 33,993 | 972 | `get_contact_id`, `create`, `redeem`, `invite`, `pending_child`, `respond`, `cancel`, `list_family`, `unlink` | user JWT; role per action |
| 2 | `auth-bootstrap` | readable TS | 4,302 | 140 | `set_role`, `create_family` | user JWT + verified email |
| 3 | `device-command` | minified | 18,124 | 2 | `create`, `poll`, `ack` | parent JWT (create); device headers (poll/ack) |
| 4 | `device-register` | minified | 9,086 | 2 | `register` | child JWT + verified email |
| 5 | `device-policy` | minified | 11,174 | 2 | `update` | parent JWT + verified email |
| 6 | `device-telemetry` | minified | 12,461 | 2 | `heartbeat`, `usage_upload`, `location_upload`, `apps_upload` | device headers only |
| 7 | `family-admin` | minified | 9,386 | 2 | `revoke_device`, `recover_device`, `ack_alert`, `purge_data`, `update_retention` | parent JWT + verified email |
| 8 | `remote-session` | minified | 12,848 | 2 | `request`, `pending_child`, `respond`, `start`, `end`, `ice` | user JWT; role per action |
| 9 | `cron` | minified | 3,791 | 2 | `expire_sessions`, `detect_offline` | shared secret header |

Every function is a single `Deno.serve` handler with a `{action: string}` body (except `device-telemetry`, `cron` and the
single-action functions `device-register` / `device-policy`, which still use the same envelope), an `OPTIONS` preflight
and a `POST`-only guard. Every function instantiates the **service-role** client:

```ts
// _shared/auth.ts:49-66 (pairing); the same construction is inlined in each bundle
cachedClient = createClient(url, serviceKey, {
  auth: { persistSession: false, autoRefreshToken: false },
  global: { headers: { "X-Client-Info": "parentcontrol-edge/1" } },
});
```

Consequence, **VERIFIED** by reading all nine: RLS never applies on these code paths. Every authorisation decision in
the product is application code in these nine handlers. There is no second line of defence in the database for a
handler that forgets a check.

## 4. Shared modules

| Module | Chars | Lines | SHA-256 (prefix) | What it provides |
| --- | --- | --- | --- | --- |
| `_shared/auth.ts` | 9,920 | 338 | `34b46f5a30…` | service client, `requireUser`, `requireRole`, family/membership assertions, `requireActiveDeviceForParent`, `requireDevice` |
| `_shared/envelope.ts` | 3,517 | 112 | `cf4a69115b…` | `ApiError`, `ok`/`fail`, `errorResponse`, `readJson`, `requireAction`, `ensureNoError` |
| `_shared/validation.ts` | 12,640 | 419 | `3b81768322…` | regexes, typed readers, CSPRNG code/Child ID, `sha256Hex`, `identifierHash`, constant-time helpers |
| `_shared/rate_limit.ts` | 7,148 | 211 | `754502ef27…` | pairing attempt / creation / invite quotas |
| `_shared/audit.ts` | 1,101 | 38 | `649d277ed6…` | `recordAudit` → `audit_logs` insert |
| `_shared/cors.ts` | 490 | 13 | `33ec5b77c5…` | wildcard CORS headers + preflight response |

Full digests are in the capture manifest. `rate_limit.ts` exists only in the `pairing` tree; the seven bundles inline
only the helpers they call, so a module listed here is not necessarily present as a file under every function.

### Dependency matrix (VERIFIED for the two readable functions, INFERRED from inlined identifiers for bundles)

| Function | auth | envelope | validation | audit | cors | rate_limit |
| --- | --- | --- | --- | --- | --- | --- |
| `pairing` | ● | ● | ● | ● | ● | ● |
| `auth-bootstrap` | ● | ● | ● | ● | ● | — |
| `device-command` | ● | ● | ● | ● | ● | — |
| `device-register` | ● | ● | ● | ● | ● | — |
| `device-policy` | ● | ● | ● | ● | ● | — |
| `device-telemetry` | ● | ● | ● | — | ● | — |
| `family-admin` | ● | ● | ● | ● | ● | — |
| `remote-session` | ● | ● | ● | ● | ● | — |
| `cron` | — (secret) | ● | — | — | ● | — |

`device-telemetry` writes no `audit_logs` rows at all (**VERIFIED** by reading the bundle: no insert into that table
appears). Its activity is therefore represented only by the effect on device state and by whatever `safety_alerts` rows
it creates.

## 5. Capture provenance

| Function | SHA-256 |
| --- | --- |
| `pairing` | `427d419d4f691cfbc50ccfbc63c500fdcb8f5838cbaa5105b4a58f8551424307` |
| `auth-bootstrap` | `34cf673247a61a91dbeda77c14c06d01184aad7a0724b5f7eaeb9d2f85b7383b` |
| `device-command` | `4e31901a2891986bd62ac58c9a9af154b5d20f67be6aabc27e44b51cec406054` |
| `device-register` | `712d46b076b11ced8992a0e91149ac953ea5b5a71f41dc755fd97beca97a4c27` |
| `device-policy` | `3efdb19b7159fce8befc960b34d7af9ceaa756c81ea305a01c4f79bc7d332211` |
| `device-telemetry` | `b3ca5221347a5f753de6bd7936d9efec2298b8362532c8752c258daaff1befbd` |
| `family-admin` | `b6864fdda7ad52ffc75b2eff8f6f973f8b75a3a04065c9b6941b3638fe615de7` |
| `remote-session` | `85e30c3c6da5d279e5ecdd0cb962c759dbab5fe59b82ffa43b23f4723e987c0c` |
| `cron` | `4cb4bd11e28446236efd7e6e152953ad52df453cba078e543be7301955402258` |
| `_shared/auth.ts` | `34b46f5a302f5a6ad4330c2c7a13fa8dc4a3660371f51843606538435735c5f2` |
| `_shared/envelope.ts` | `cf4a69115b6fd94a4a9bf464cb5002a6d399bfdaec589bb45572b70ca19eed7c` |
| `_shared/validation.ts` | `3b81768322eb5aad589a2ba7d0627bc064915a392aff3fb5acaf23617ff09bb7` |
| `_shared/rate_limit.ts` | `754502ef27b6f29f589bc1438d069e141f785683a2f846e70e53f3b0b3a97dee` |
| `_shared/audit.ts` | `649d277ed6358d11da994c7845cd8f9e040beffafcb241bc5cd7ac464cc017e7` |
| `_shared/cors.ts` | `33ec5b77c5f14bae7becf96fd4656014144227cf450827d2f8bc9dba5e136e1f` |

These digests identify **the text the editor served on 2026-10-30**. They are not deploy digests: the dashboard does not
expose the artefact hash of the running bundle, so equality between the editor text and the deployed bytes is
**INFERRED**, not proven. A deploy performed after capture would invalidate them silently; re-read before relying on
them.

## 6. Limits of this inventory

1. **Minified bodies.** Seven of nine functions are 2-line bundles with single-letter identifiers. Guards that were
   found are real; the absence of a guard is weaker evidence, because an identifier could be named anything. Where a
   negative claim matters it is marked **NOT VERIFIED** rather than "absent".
2. **No source maps.** The original module boundaries and comments inside the bundles are unavailable. Shared-module
   behaviour was characterised from the readable copies under `pairing/`, then matched by behaviour (for example the
   identical `ApiError` class, identical 512 KB body cap, identical `err.name`-only logging) in each bundle. That match
   is **INFERRED**, not byte-identical.
3. **Editor text, not repository text.** No git history, no review trail, no build reproducibility. There is no way to
   tell from here who changed what or when.
4. **Runtime configuration is out of scope.** Environment variables (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`,
   `PAIRING_HASH_PEPPER`, `CRON_SECRET`, `TURN_SECRET`, `STUN_URL`, `TURN_URL`) are read but their deployed values were
   not read. Whether `PAIRING_HASH_PEPPER` and `CRON_SECRET` are actually set is **NOT VERIFIED**; the code's behaviour
   when they are not set is **VERIFIED**.
5. **No request was made.** Every runtime claim is source-derived. Nothing here proves the deployed bundle behaves as
   its source reads.

## 7. Owner-authorised export procedure (PROPOSED — NOT APPLIED)

Exporting the source into the repository is the only way to get reviewable diffs, source maps and a history. It needs
the owner's project credentials (gate G3 in [12-g3-baseline-plan.md](12-g3-baseline-plan.md)); nothing in this phase
attempted it.

```bash
# prerequisite: a Supabase access token or interactive login, and the DB password for link
supabase login                                  # owner-only; writes a token to the CLI config
supabase link --project-ref hhqgreaoqulmfwfwarhc # prompts for the database password
supabase functions download pairing auth-bootstrap device-command device-register \
  device-policy device-telemetry family-admin remote-session cron
supabase functions download pairing --legacy-bundle   # only if an unminified copy is still retained server-side
git add supabase/functions && git commit -m "chore(edge): import deployed function source"
```

Notes for whoever runs it:

- `link` needs the database password. Do not paste it into a shell history; use the prompt.
- `functions download` writes into `supabase/functions/<slug>/`. It does not overwrite a deploy; it only reads.
- The dashboard offers the same thing per function under **Download** → *Download as ZIP*. A ZIP attempt during this
  phase produced a transient `.tmp` file that disappeared before it could be read, so the CLI path is the more reliable
  one.
- After import, treat the imported tree as evidence, not as a build source: it is the bundle, not the original modules,
  unless `--legacy-bundle` returns the pre-bundle form.
- Then add `supabase/functions/` to review scope and re-run 14 against the repository copy with line numbers.

## 8. Open items

| # | Item | Status |
| --- | --- | --- |
| I1 | `supabase/functions/` absent from the repository | **VERIFIED absent**; export PROPOSED, needs G3 |
| I2 | Bundle → original module mapping | **NOT VERIFIED** (no source maps) |
| I3 | Editor text equals deployed bytes | **INFERRED** |
| I4 | `PAIRING_HASH_PEPPER` / `CRON_SECRET` / `TURN_*` deployed values | **NOT VERIFIED** (not read by design) |
| I5 | Local `config.toml` shows different API schemas than production | **VERIFIED drift**, documentation only |
| I6 | `device-telemetry` writes no audit rows | **VERIFIED** |
