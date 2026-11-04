# `backend/supabase/migrations` — deliberately EMPTY, and why

There are no `.sql` files in this directory. That is a decision, not an omission.

## 1. Where the schema actually lives

Four authored migration artefacts exist, and all four are in
[`docs/stage2/migrations/`](../../../docs/stage2/migrations/):

| File | Lines | Status | What it is |
| --- | --- | --- | --- |
| `A3-staging-load-v1.sql` | 1575 | PREPARED — NOT EXECUTED | The load-fixed staging schema: tables, RLS policies, the SECTION 0 wrong-project sentinel guard. PostgreSQL 17 assumed. |
| `A3b-functions-triggers-candidate.sql` | 959 | PREPARED — **admissibility ruling required** | Candidate bodies for the 9 captured SQL functions whose absence blocks 25 of 29 dependents (17 RLS policies + 8 triggers). Needs the owner to rule that call-site + body derivation of return types is admissible. |
| `A3c-notification-backend.sql` | 1317 | PREPARED — NOT EXECUTED | Push-token store + notification queue. Today push has no schema home at all (`firebase/SETUP-CHECKLIST.md`:99). |
| `A3d-firebase-identity-mapping.sql` | 663 | PREPARED — NOT EXECUTED | The Firebase-identity mapping (M-B) behind the Third-Party Auth bridge decision. |

Plus the patches under [`docs/stage2/patches/`](../../../docs/stage2/patches/)
(`S2-P01` … `S2-P03`), which correct the E2/E3/E4 findings in already-authored DDL.

## 2. Why they are not copied here

1. **No duplicates.** The implementation brief names this tree as *target structure*, explicitly
   "not permission to create duplicate or unnecessary packages". A second copy of 4,514 lines of
   DDL would be a second thing to keep in sync and a second chance to paste the wrong one.
2. **The 200-line rule.** `backend` **is** one of the scanned roots of
   [`scripts/check_line_counts.dart`](../../../scripts/check_line_counts.dart), and `.sql` **is**
   one of its extensions (`maxLines = 200`). `docs` is not scanned. Moving these files here would
   put four 663–1575-line artefacts in violation of a gate the project passes today at 0
   violations across 397 hand-written files — and a migration must not be split to satisfy a style
   gate, because a schema load has to be **one transaction** to be safe.
3. **They are not loadable yet.** `parent-control-staging` has **0 tables**. A3 has not run, and
   running it needs the owner's signature: **A7-R** / **A8-R** / **A9** are all `STATUS: UNSIGNED`
   ([docs/stage2/approval-package-v3-implementation-instruments.md](../../../docs/stage2/approval-package-v3-implementation-instruments.md)).
   Nothing in this repository may execute SQL. The only permitted path is the owner pasting into
   the **browser** SQL Editor of `parent-control-staging` / `dzonzgngwxclhfnvxtvu` — never
   `parent-control-prod` / `hhqgreaoqulmfwfwarhc`, which is never opened, queried, configured or
   written.

## 3. Ordering, if and when the owner loads them

`A3` → `A3b` (after the admissibility ruling) → `A3d` → `A3c`, then the `S2-P0x` patches, then the
Edge Functions in [`../functions/`](../functions/README.md), then the secrets in
[`../config/environment.md`](../config/environment.md). The functions lane is inert before the
schema lands: every read fails at first contact and every `db.rpc(...)` returns `404`/`PGRST202`.
Secrets come last because A9 depends on A3 having created the roles the secrets are scoped to.

## 4. What would make this directory non-empty legitimately

Only this: a signed instrument that says a specific file is landed in staging, at which point a
*forward-only* migration belongs here under the 200-line rule (one statement group per file), with
the landed-date and the dashboard confirmation recorded in its header. Not a copy of the artefacts
above.
