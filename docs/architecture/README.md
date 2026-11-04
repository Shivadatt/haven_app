# Haven — architecture (as built, as of 2026-11-04)

Four documents. They describe **what is in this repository right now**, not the intended end state.
Every statement is either cited to a file in this repo, labelled `INFERRED —`, or labelled with the
project's own status vocabulary (`NOT DEPLOYED`, `NOT EXECUTED`, `NOT VERIFIED`,
`BLOCKED — SPECIFICATION REQUIRED`).

| File | Covers |
| --- | --- |
| [01-system-overview.md](01-system-overview.md) | the three codebases, what connects them today (nothing), and the validators that pass |
| [02-auth-and-identity.md](02-auth-and-identity.md) | `IDENTITY_MODE`, the two captured auth channels, the device credential, and what is refused |
| [03-data-and-backend-contract.md](03-data-and-backend-contract.md) | tables/RPCs/slugs the code references, the envelope contract, and the deploy gates |
| [04-refusal-model.md](04-refusal-model.md) | the deliberate `blocked(...)` design — why most screens state a gap instead of showing data |

## Read this before using these files as a status report

- **Nothing is deployed.** `parent-control-staging` runs 0 tables, 0 SQL functions, 0 Edge Functions,
  0 secrets; `haven-staging` has 0 registered apps and 0 credentials
  ([`../backend/supabase/functions/README.md`](../../backend/supabase/functions/README.md) §1,
  [`../backend/firebase/SETUP.md`](../../backend/firebase/SETUP.md) §1).
- **No feature has been exercised end to end.** A Flutter screen rendering a controller is not a
  working feature; see [04](04-refusal-model.md) for which screens therefore refuse.
- **The stage-1 target architecture is a separate document** —
  [`docs/stage1/02-architecture.md`](../../docs/stage1/02-architecture.md). These files do not
  restate it; they record what was actually written against it.
- Production is never a target of anything here. Staging refs only: Supabase
  `parent-control-staging`/`dzonzgngwxclhfnvxtvu`, Firebase `haven-staging`/`haven-staging-46822`.
