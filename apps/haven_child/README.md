# haven_child

Haven Child Companion — the child-side Android app for Phase 3.

This app mirrors the layout of `apps/haven_app` 1:1 (GetX bindings, named
routes, flat theme tokens, shared components) and depends on the same
`packages/haven_{core,models,api}` seams. It ships its own Android identity:
`applicationId`/`namespace` are `com.haven.child` (decision D-1), and its
Gradle setup mirrors the parent's hardening (AGP 9.0.1, Kotlin 2.3.20,
Gradle 9.1.0, build output redirected into `apps/haven_child/build/`).

## Stage 1 scope

App foundation only: scaffold, routes, theme, shared components and placeholder
pages for `/splash`, `/onboarding`, `/profile`, `/device`, `/permissions`.
Feature controllers, storage/session bindings and the real test suite are added
by the follow-up stage agents against the extension points marked
"Agent 2" / "Agent 3" in the code.

## Deliberate local-only posture

No permissions are declared in any manifest (main, debug, profile): Stage 1 is
fully local, so even `INTERNET` is intentionally absent and debugging stays on
the USB/adb transport. No cloud package (Supabase/Firebase/http) may enter
`pubspec.yaml` at this stage.

## Build

Flutter is FVM-pinned (3.44.6). `android/local.properties` must point at the
Android SDK and the pinned Flutter; `ANDROID_HOME` is not set in this
environment.

```
fvm flutter pub get
fvm flutter analyze
fvm flutter test
```
