# S2-INSP-02 — Firebase Console, read-only inspection

**Record ID:** S2-INSP-02
**Date/time (UTC):** 2026-10-30T08:05Z – 2026-10-30T08:09Z
**Operator:** agent session (browser UI only)
**Classification:** READ-ONLY, informational. No project created, no service enabled, no app registered, no credential
generated, no FCM setting touched, no production config copied.
**Approval reference:** none required for read-only inspection. This does **not** constitute A12 / G2 / G7 approval.
**SCREENSHOT EVIDENCE: NOT VERIFIED** (header added 2026-11-02 for format consistency with the other evidence records — this is not new evidence).

## Page inspected

`https://console.firebase.google.com/` — project overview / "Welcome back to Firebase!"

## Observations (verbatim from page text)

- Signed-in Google account (account button): `Shiwa Goswa!i (shiwa2172000@gmail.com)`.
- Greeting: `Hello, Shiwa`.
- Project list: **1 – 1 of 1**, single entry `FlutterFlowWIthFIreBase`, project ID
  `flutter-flow-w-ith-f-ir-6592ib`.
- That project's applicationId/package is `com.mycompany.flutterflowwithfirebase` per
  `firebase/SETUP-CHECKLIST.md:7` — an unrelated demo, explicitly not to be reused.
- `Create a new Firebase project` button is present and was **not** clicked.
- No project named `parent-control-*`, `haven-*`, or any Haven/family-safety project appears.

## Findings

| Claim | Status |
| --- | --- |
| Google account used for Firebase is `shiwa2172000@gmail.com` | `VERIFIED` |
| Exactly one Firebase project is visible | `VERIFIED` |
| A dedicated Haven / `parent-control` Firebase project exists | `VERIFIED` — it does **not** |
| The visible project is the unrelated FlutterFlow demo | `VERIFIED` |
| G2 (choose/create the Firebase project) is therefore still an open decision | `VERIFIED` |
| Production Firebase config unchanged | `VERIFIED` — read-only navigation only |
| Whether *another* Google account owns a Haven project | `NOT VERIFIED` — requires switching accounts, not permitted here |

## Identity note (material)

Three distinct identities are now recorded across the programme:

| Surface | Account |
| --- | --- |
| Supabase dashboard (owns production project) | `spg7753@gmail.com` |
| Firebase console (owns no Haven project) | `shiwa2172000@gmail.com` |
| Firebase CLI account recorded in Stage 1 as "wrong, must log out" | `om-event*` (`firebase/SETUP-CHECKLIST.md:57`) |

So the Supabase owner and the Firebase owner are **different Google identities**. Any future work that links the two
(service-account JSON into Supabase Edge secrets, G7) crosses that boundary and needs an explicit owner decision about
which identity holds the Firebase project — it is not resolvable by browsing.

## Deferred status

G2 and G7 remain deferred. No Firebase action of any kind occurred. `BLOCKED — APPROVAL REQUIRED` (A12, outside Stage 2).

## SUPERSESSION ADDENDUM (2026-11-02, S2-DOC-02)

**Asserted here:** at 2026-10-30T08:05–08:09Z the account listed `1 – 1 of 1` (the unrelated FlutterFlow demo only), that a dedicated Haven /
`parent-control` Firebase project **does not exist**, and that G2 was therefore still open — all read-only, no Firebase action.

**Superseded by [S2-CREATE-01](S2-CREATE-01-new-projects.md):** `1 – 1 of 1` → `1 – 2 of 2` (CREATE-01 §3.3); "a dedicated Haven Firebase project does
**not** exist" → `haven-staging` / `haven-staging-46822` was created later the same day on a direct owner instruction, with A12 ungranted and the Stage 2
Firebase prohibition exceeded (§3.1; R-36 in [04](../04-risks-rollback-approvals.md) §1). The new shell has **no apps, no credentials and no FCM
configuration** (§3.1, §4.4), so it settles no G2/G7 decision and unblocks no Stage 2 step.

**Stands, and is now more material:** the §Identity note — three identities, with a real Firebase project on the non-Supabase one. Observations here
remain valid for the window captured; this record is append-only and nothing above is deleted or rewritten.
