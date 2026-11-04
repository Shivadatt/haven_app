# `backend/supabase/functions` — the re-authored Edge Function lane

**Status: written, type-checked, linted, offline-tested. NOTHING IS DEPLOYED.**
`parent-control-staging` currently runs **0 Edge Functions** (verified in the browser dashboard,
and recorded in [docs/stage2/functions/DEPLOYMENT-MAP.md](../../../docs/stage2/functions/DEPLOYMENT-MAP.md)).
Deployment is gated on the owner signing **A7-R** and **A8-R**, both of which are
`STATUS: UNSIGNED`. Writing this directory is not a deployment and does not authorise one.

## 1. Provenance — what this directory is, and what it is not

These are **re-authorings from the stage-1 evidence**, not copies of the shipped bundles. The
bundles were read only as minified `index.js` and as captured request/response behaviour
(`docs/stage1/captures/*`, `docs/stage1/14-*.md`, `docs/stage1/15-*.md`); no original source map,
plain-language spec, or un-minified body was ever available. Every slug therefore carries:

> `RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION`

That label is mandatory per the implementation brief and must not be removed by a future edit.
**All nine slugs carry it** — the seven the brief lists as minified (`device-command`,
`device-register`, `device-policy`, `device-telemetry`, `family-admin`, `remote-session`, `cron`)
and the two whose capture called the text "readable" while the repository still held none of it
(`auth-bootstrap`, `pairing`). 41 files, every one of them labelled.
The deployable bundles, the build script, and the per-slug deployment verdict live in
`docs/stage2/functions/` — this directory is the source of truth for *reading and editing the
logic*, that directory is the source of truth for *shipping it*.

Note on the 200-line rule and those bundles: `docs/stage2/functions/deploy/*.bundle.ts` run
214–1084 lines each (a single-file bundle is one browser paste, so it cannot be split). They are
outside the rule's scanned roots (`apps`, `packages`, `android_native`, `backend`, `scripts`),
which is why the rule holds here at 41 files ≤ 200 without breaking the deploy package.

Two scopes are additionally **`NOT DEPLOYABLE WITHOUT SPEC`**, scoped to the specific behaviour,
not to the whole file:

| Slug | Scope that is blocked | Why |
| --- | --- | --- |
| `device-policy` | the key-allowlist part of `update` | `capture:95` names three allowlists as `V`/`X`/`Z`; their **contents appear nowhere** in the evidence — grep of the whole repository finds no file that names a single policy key. Authoring plausible key names would be inventing the business logic this function exists to police. |
| `device-command` | `sync_policy`, `request_usage`, `request_location`, `end_session` | `14:221` says payloads are "allowlisted per command type" but no anchor names an allowed key for these four. They fail closed with `501 command_spec_missing`. `apply_policy` and `custom` **are** authored from evidence. |

The file header in each of those two lanes asserts the same thing at the top of the file, so the
block is visible before the code is. `tests/auth_bootstrap_test.ts` reads
`device-policy/index.ts` as text and **fails if either block is removed** — the label is a tested
invariant, not a comment.

## 2. Layout

```
_shared/          envelope, cors, readers, validation, tail, identifiers, identity,
                  auth, family, device_authority, quotas, rate_limit, audit, db
auth-bootstrap/   index.ts + set_role.ts + create_family.ts
cron/             index.ts
device-command/   index.ts + create.ts + poll_ack.ts
device-policy/    index.ts
device-register/  index.ts + register_flow.ts
device-telemetry/ index.ts + heartbeat.ts
family-admin/     index.ts
pairing/          index.ts + shared.ts + unlink.ts
remote-session/   index.ts + lifecycle.ts + media.ts
deno.json         import map + lock:false + the ONE lint exclusion (see §4)
```

`index.ts` in each slug is the **entry point**: it calls `Deno.serve` at module scope. That is why
no test imports an `index.ts` — importing one attempts to bind `0.0.0.0:8000` and dies with
`NotCapable`. All testable logic was moved into the sibling modules (`set_role.ts`, `create.ts`,
`poll_ack.ts`, `register_flow.ts`, `heartbeat.ts`, `lifecycle.ts`, `media.ts`, `shared.ts`), which
export plain handler functions and are imported freely by `../tests/`.

The split was made for the **strict 200-line rule** enforced over hand-written `.dart .kt .java
.sql .ts` by [`scripts/check_line_counts.dart`](../../../scripts/check_line_counts.dart). Behaviour,
labels and evidence anchors were carried across unchanged; each split file states where its other
half lives.

## 3. Check it

```
cd backend/supabase/functions
deno check $(ls */*.ts)     # 41 files, 0 errors
deno lint                   # 41 files, 0 problems
cd ../tests && deno test --allow-env --allow-read   # see tests/README.md
```

Verified on Deno **2.9.4** on 2026-11-04. `deno fmt` is **never** run on this tree: it rewraps
lines and pushes the split files back past 200, silently breaking the §13 line-count gate.

## 4. The one lint exclusion, and why it exists

`deno.json` excludes `no-explicit-any` for this tree. The reason is `_shared/db.ts`: the
service-role client is **hand-typed** because no generated `Database` type can be imported —
`parent-control-staging` holds 0 tables, and `supabase gen types` is a CLI command this project is
not authorised to run. Without that seam, `deno check` resolves every `.from("table")` to `never`.

The exclusion is not a blank cheque: the `any` values are confined to that interface and to the row
objects the loaders return. **Every function parameter that can be typed is typed `DbClient`** —
that conversion is what took the `_shared` lint story from 35 problems to 0. If a generated types
file is ever produced and committed, delete the exclusion and re-tighten `_shared/db.ts`.

## 5. Environment

Read names only — see [../config/environment.md](../config/environment.md). Six variables, seven
read sites, **all six currently NOT CREATED** because the secret-creation instrument (A9) is
unsigned. No value is stored in this repository, in a comment, or in a test.

## 6. Related

- [../tests/README.md](../tests/README.md) — what the 82 offline tests do and refuse to claim
- [../config/environment.md](../config/environment.md) — env names, browser-only setup procedure
- [../migrations/README.md](../migrations/README.md) — why this lane is not yet loadable
- [docs/stage2/functions/DEPLOYMENT-MAP.md](../../../docs/stage2/functions/DEPLOYMENT-MAP.md) —
  the signable deployment gates
