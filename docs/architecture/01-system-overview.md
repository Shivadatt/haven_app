# 01 — System overview (what exists as code)

## 1. Three codebases, one repository

| Lane | Path | Language / toolchain | What it is |
| --- | --- | --- | --- |
| Parent app | `apps/haven_app/` | Dart, Flutter **3.44.6** via FVM, GetX | 16 feature directories, 124 Dart files under `lib/features/`, plus `app/`, `core/`, `shared/` |
| Shared pure-Dart packages | `packages/haven_core/`, `packages/haven_models/`, `packages/haven_api/` | Dart | result/failure vocabulary, typed wire models, and the backend seam |
| Child agent | `android_native/child_services/` | Kotlin | permission, monitoring, location, device-admin, communication and platform-bridge lane |
| Backend | `backend/supabase/functions/` | TypeScript, Deno | 9 Edge Function slugs + `_shared/`, 41 files, all ≤ 200 lines |
| Backend docs | `backend/supabase/{tests,config,migrations}/`, `backend/firebase/` | TS + Markdown | 82 offline tests, names-only env table, migration pointer, Firebase guide |

`docs/stage1/` and `docs/stage2/` hold the evidence corpus and the approval instruments; they are not
code and are not restated here.

## 2. What connects them today: nothing

This is the single most important architectural fact, and it is not a shortfall of the code — it is
the deployment state:

- Supabase `parent-control-staging` has **0 tables, 0 SQL functions, 0 Edge Functions, 0 secrets**
  (`docs/stage2/functions/DEPLOYMENT-MAP.md` §1).
- Firebase `haven-staging` has **0 registered apps, no `google-services.json`, 0 credentials**
  (`docs/stage2/S2-A2-firebase-console-audit.md:216-217`, `:244`).
- Therefore a running app cannot read a device row, call an RPC, invoke a slug, or receive a push.
  It reaches `Supabase.initialize` only if `--dart-define` supplies a URL and anon key
  (`packages/haven_api/lib/src/haven_backend.dart:35-40`), and neither is provided by this repo.

The intended data path (Flutter → Supabase Auth → Edge Function (service role) → Postgres/RLS →
child agent poll) is documented as a **design** in `docs/stage1/02-architecture.md` and is not
exercised anywhere. Do not describe it as working.

## 3. Layering actually used in the app

```
lib/main.dart            reads --dart-define names only, no secrets
lib/app/                 app.dart, bindings/, routes/, theme/         shell
lib/core/                constants/ errors/ network/ permissions/
                         storage/ utils/ widgets/                     cross-feature
lib/features/<name>/     bindings/ controllers/ data/ views/ (+ services/)
packages/haven_core/     result.dart failures.dart blocked.dart retry.dart ...
packages/haven_models/   typed wire models + enums (enums_identity/commands/sessions/wire)
packages/haven_api/      contracts + implementations of the backend seam
```

Conventions the code follows (verified by reading, and by `fvm flutter analyze` reporting
`No issues found!` on 2026-11-04):

- **Feature-first with a binding per feature.** GetX bindings construct repositories and controllers;
  views contain no business logic and make no SDK calls.
- **Typed models only.** Wire shapes live in `packages/haven_models`; controllers do not parse JSON.
- **The repository owns the refusal.** `data/*_repository.dart` returns
  `Result`/`blocked(...)` values rather than throwing or returning empty lists — see
  [04-refusal-model.md](04-refusal-model.md).
- **`haven_api` is the only place that knows about Supabase/Firebase SDKs**, so the app never touches
  a client directly (`packages/haven_api/lib/src/supabase_data.dart`, `edge_caller_impl.dart`,
  `push_transport_impl.dart`).

## 4. Backend shape

`backend/supabase/functions/` splits each slug into an entry `index.ts` (calls `Deno.serve` at module
scope) plus action modules that hold the testable logic — `auth-bootstrap/{set_role,create_family}.ts`,
`device-command/{create,poll_ack}.ts`, `device-register/register_flow.ts`,
`device-telemetry/heartbeat.ts`, `remote-session/{lifecycle,media}.ts`, `pairing/{shared}.ts`. The
split exists to satisfy the 200-line rule without changing behaviour; the entry files are **not
importable by a test** because starting `Deno.serve` binds a port (`NotCapable`), which is why the
test lane imports only the action modules
(`backend/supabase/tests/README.md` §3).

Shared code sits in `_shared/`: `db.ts` (the hand-typed `DbClient` seam), `auth.ts`, `identity.ts`,
`family.ts`, `device_authority.ts`, `envelope.ts`, `cors.ts`, `readers.ts`, `validation.ts`,
`identifiers.ts`, `quotas.ts`, `rate_limit.ts`, `audit.ts`, `tail.ts`.

## 5. Validators — what passes, on what date

Run from `D:/control`:

| Check | Command | Result |
| --- | --- | --- |
| Toolchain | `fvm flutter --version` | **Flutter 3.44.6** • framework `ee80f08bbf` • engine `d3a3293399` (2026-11-04) |
| Static analysis | `fvm flutter analyze` (in `apps/haven_app`) | **No issues found!** (127.8 s, 2026-11-04) |
| Line-count gate | `fvm dart run scripts/check_line_counts.dart` | **397 hand-written files scanned, 0 violations** (max 200 lines; `.dart .kt .java .sql .ts`) |
| Deno types | `deno check` in `backend/supabase/functions` | clean, 41 files |
| Deno lint | `deno lint` in functions and tests | 41 files / 10 files, **0 problems** |
| Backend tests | `deno test --allow-env --allow-read` in `backend/supabase/tests` | **82 passed, 0 failed** |
| Dart tests | `fvm flutter test` per package | see [../testing/](../testing/README.md) |

`deno fmt` is **never** run on the split files: it rewraps and pushes them back over 200 lines.

## 6. Deliberate absences

- No committed credentials of any kind; `.gitignore:14` blocks `google-services.json` (pattern with
  no instance).
- No `.env` loader and no runtime config fetch — configuration arrives only as build-time
  `--dart-define` names (`apps/haven_app/lib/main.dart:8-13`).
- No schema files under `backend/supabase/migrations/` — the four authored DDL artefacts stay in
  `docs/stage2/migrations/` and are `PREPARED — NOT EXECUTED`
  ([`backend/supabase/migrations/README.md`](../../backend/supabase/migrations/README.md)).
- No fourth codebase (no server, no web app, no iOS target).
