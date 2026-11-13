# D-4 drift-detection experiment (Agent 3, 2026-11-13)

Purpose: prove the cross-language agreement tests fail on REAL Kotlin-side drift, as required by
`STAGE_2_OWNER_DECISIONS.md` §2.1/§2.3 and the Stage-2 brief ("do not claim drift protection unless the test
actually detects drift"). Nothing else in the tree was touched.

## Procedure (all commands from `D:/control` unless noted)

1. `sha256sum android_native/child_services/platform_bridge/BridgeContract.kt`
   -> `ffa1f71439955c3ebe8719b29bb8a0ee797e3a0a375ab01f5e087880f0b54018`
2. Mutate exactly one constant, temporarily:
   `const val KEY_API_LEVEL = "apiLevel"` -> `const val KEY_API_LEVEL = "apiLevel_DRIFT"` (line 18).
3. Run both agreement suites against the mutated Kotlin.
4. Reverse the same `sed`, re-hash, re-run.

## Observed while drifted

Parent (`apps/haven_app`, `fvm flutter test test/permissions/cross_language_key_agreement_test.dart`) — exit non-zero:

```
00:00 +2 -1: every envelope key Kotlin sends is read by Dart under the same string [E]
  KEY_API_LEVEL = "apiLevel_DRIFT" in BridgeContract.kt but the Dart decoders no longer index that string — drift, one key at a time, exactly as D-4 requires
00:00 +6 -1: Some tests failed.
```

Child (`apps/haven_child`, `fvm flutter test test/native/child_native_key_agreement_test.dart`) — exit non-zero:

```
00:00 +4 -1: per-item agreement with the Kotlin source on disk envelope.apiLevel [E]
    Actual: 'apiLevel_DRIFT'
```

Both failures name the drifted constant and the drifted value, i.e. the Kotlin file on disk is the input being
compared against — the checks are not Dart-literal-vs-Dart-literal.

## Restore evidence

- Post-restore `sha256sum` = `ffa1f71439955c3ebe8719b29bb8a0ee797e3a0a375ab01f5e087880f0b54018` — **identical to
  step 1**, so `BridgeContract.kt` is byte-for-byte back.
- `git diff --stat -- android_native/` -> empty (only an informational CRLF warning from git's own normalization).
- Clean re-runs after restore: parent agreement file `+7: All tests passed!`; child `test/native` `+36: All tests passed!`.

## Limits of this experiment (stated, not hidden)

- One key was mutated. The **add/rename-both-directions** cases are covered by the count/set assertions
  (`hasLength(9)`, `expect(dartEnvelopeKeys, kotlinKeys.values.toSet())`,
  `expect(bridge.keys.where(startsWith('ERROR_')), dartMirror.keys.toSet())`), which were read and pass, but were
  not each separately exercised by a mutation in this run.
- The tests read the Kotlin tree **read-only**; they do not compile Kotlin and confer no device or runtime
  evidence. Ladder ceiling stays level 2 (`STAGE_2_OWNER_DECISIONS.md` §6).
