# `backend/supabase/tests` — offline decision tests for the re-authored Edge Function lane

## Run it

```
cd backend/supabase/tests
deno test --allow-env --allow-read
```

Verified on Deno **2.9.4** on 2026-11-04: **81 tests, 7 files, 0 failures**, with type checking
on (no `--no-check`). `--allow-env` is needed because `identifierHash` reads `PAIRING_HASH_PEPPER`
and one test checks whether the runner's environment already holds the staging secrets; the tests
**never set, delete, or print a value**. `--allow-read` is needed by exactly one test that reads
`device-policy/index.ts` as text (see §3).

## 1. What a pass means — and what it does not

A pass means: **the stage-2 re-authored logic behaves as its own headers claim.** It is not parity
with the deployed bundles (all nine slugs stay `RE-AUTHORED FROM SPECIFICATION — NO PARITY
VERIFICATION`), and it is not an executed row of
[`docs/stage1/15-edge-function-test-plan.md`](../../../docs/stage1/15-edge-function-test-plan.md):
that plan is HTTP-level, against a seeded scratch project, and remains **`NOT EXECUTED`**. Each test
names the 15-* case id whose *decision* it reproduces, never the case itself.

Nothing here touches Supabase or Firebase, opens a socket, or runs SQL. Database truth — CHECK
constraints, triggers, RPC bodies, RLS — cannot be tested this way and is not claimed.

## 2. How the handlers are reached

`tests/stub_db.ts` implements a hand-written stand-in for the service-role client: a fluent,
thenable builder that records every predicate and payload and answers from a reply table. It exists
because the functions run with `service_role`, so RLS does not apply to any of their queries
(14:245-246) — **the predicates are the control**, and a test that only reads the status code
cannot see a missing `.eq()`. Where a guard matters, the tests assert the recorded predicates, not
just the verdict.

## 3. Why no `index.ts` is imported

Every function entry point calls `Deno.serve` at module scope, so importing one starts a listener
inside the test runner (`device-policy/index.ts` did exactly that on 2026-11-04). The split done
during this port moved each action body into its own module for the 200-line rule, and those
modules are what these tests import. The one exception is read as **text** instead: the
device-policy allowlist guard, which must stay empty until the owner supplies the bundle's
constants V/X/Z.

Consequence, stated honestly: the `index.ts` wiring — CORS-first ordering, `requireUser`
composition, the action dispatch itself — is **verified by `deno check` and by reading, not by
these tests**. `PE-A03` (`email_not_verified`) and every `TE-16`/`PE-CR*` cron case live in that
wiring and are therefore not covered.

## 4. Coverage map

| File | Covers (15-* decisions reproduced) |
|---|---|
| `envelope_test.ts` | envelope shape, `no-store`, OPTIONS/405, 512 KB gate, action bounds, `unknown_action` (PE-R07, PE-CR06), error passthrough vs fixed 500 |
| `readers_test.ts` | PE-R06, PE-C07/C09, PE-A06 shape, PE-PL02/PL03/PL04, PE-T09, PE-C03, digest and identifier formats, PE-P01 alphabet |
| `auth_roles_test.ts` | TE-05, TE-06, TE-07, TE-08, TE-09, TE-12, TE-13, TE-15 (identity half), the `IDENTITY_MODE` A13 fence, `getServiceClient` 503 |
| `guards_test.ts` | TE-01, TE-03, TE-04, TE-19, TE-20, PE-C02, PE-F02, PE-F06, PE-P11, audit actor + `audit_failed`, E7 no-lockout baseline |
| `pairing_limits_test.ts` | PE-P03, PE-P04/P06 uniform refusal, PE-P08, PE-P13, CI-01 window counts, `retry_after_seconds`, E5 two-digest finding, E6 pepper fallback |
| `handlers_test.ts` | PE-S01 steps 1-2, PE-S02, PE-S03, PE-S04, PE-S09, PE-S10, PE-T01, PE-T02, PE-T03, E4 pending-stacking baseline pinned |
| `auth_bootstrap_test.ts` | PE-A01, PE-A02, PE-A04, PE-A05, PE-A06, PE-R01, installation-id bounds, device-policy spec guard |

**Not covered, and why:** TE-02 (needs SQL: it exercises `EXECUTE` grants on a private function),
TE-14/PE-S05/PE-S06 (the `ice` credential path needs `TURN_HOST`/`TURN_SECRET` and mints an HMAC
credential — the credential is deliberately never returned to a test), TE-16/PE-CR01..07 (cron
`index.ts`), PE-C01/C04..C08 command lifecycle against a real `poll_device_commands` RPC,
PE-P02/P05/P07..P12 redeem-and-unlink flows that depend on `private.*` function bodies, PE-PL01/05/07
(device-policy is `NOT DEPLOYABLE WITHOUT SPEC`), PE-F01/F03/F05 (RPC side effects), PE-T04..T08
(location/usage batch validation runs after the device gate in `index.ts`), PE-R02..R05
(`registerDevice` needs the four-table lookup chain that `index.ts` performs), and every `CI-*`
concurrency case (they require two real transactions).

## 5. House rules for extending this directory

1. A test that cannot pass without a secret, a table, or a deployed function is written as a
   documented gap above — not as a stub that always succeeds.
2. Never seed, mutate, or delete a real project. Staging `parent-control-staging` is reached only
   through the browser dashboard by the owner.
3. When the schema lands (A3) and a deploy is approved (A7-R + A8-R), the 15-* plan becomes the
   executor of record; these tests stay as the offline regression net underneath it.

Related: [../functions/README.md](../functions/README.md) ·
[../config/environment.md](../config/environment.md)
