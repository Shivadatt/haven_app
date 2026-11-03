# Evidence — Android application identity from local build artefacts (G2, package half)

Captured 2026-10-30 on the operator workstation, read-only. No Firebase console or Play Console action, no app
registration, no credential generated. This file records what the local APKs declare; it does not prove the artefacts
are the ones that will ship.

## 1. Method

| Field | Value |
| --- | --- |
| Toolchain | Android SDK build-tools **36.0.0** (`aapt2.exe`, `apksigner.bat`), Git Bash on Windows |
| Artefacts | `%USERPROFILE%\Downloads\Haven-1.0.apk`, `Haven-1.1-release.apk`, `Haven-1.2-release.apk` |
| Commands | `aapt2 dump badging <apk>`; `apksigner verify --print-certs <apk>`; `sha256sum <apk>`; `unzip -p <apk> assets/capacitor.config.json` |
| Scope | package name, version, SDK range, Capacitor config, signing certificate, APK digest |
| Not done | No source tree comparison (the Android source is not in this repository), no Play Console check, no Firebase registration |

## 2. Results

| Field | 1.0 | 1.1-release | 1.2-release |
| --- | --- | --- | --- |
| Package name | `com.haven.familysafety` | `com.haven.familysafety` | `com.haven.familysafety` |
| versionCode / versionName | 1 / 1.0 | 2 / 1.1 | 3 / 1.2 |
| minSdk / targetSdk | 24 / 36 | 24 / 36 | 24 / 36 |
| compileSdk | 36 | 36 | 36 |
| Application label | `Haven` | `Haven` | `Haven` |
| Capacitor `appId` / `appName` | `com.haven.familysafety` / `Haven` | same | same |
| Capacitor `webDir` | `dist` | `dist-android` | `dist-android` |
| Capacitor `server` | remote `url` = `https://haven-family-safety-5s82uv3glci.qoder.website`, `cleartext: false` | `androidScheme: https` (bundled assets) | `androidScheme: https` (bundled assets) |
| Certificate DN | `CN=Haven, OU=Haven, O=Haven, L=Ahmedabad, ST=Gujarat, C=IN` | `CN=Haven, O=Haven Demo, C=US` | `CN=Haven, O=Haven Demo, C=US` |
| Certificate SHA-256 | `eaffe1600ccc526f76a2c3c2dd336a47d42001e903985b99ff59cacc5dd078e2` | `ff1ad18fcc8c77fd48c126fb369e73a7a743538f6f9a542f32f726a1a9fdd67a` | `ff1ad18fcc8c77fd48c126fb369e73a7a743538f6f9a542f32f726a1a9fdd67a` |
| Certificate SHA-1 | `a36cee9c6bee13a7ff84a70e9c33683f1d9d2f0d` | `b836708aea5cfc376f884c508aee83070e237e7a` | `b836708aea5cfc376f884c508aee83070e237e7a` |
| APK SHA-256 | `b45bb0169d6543526779b24bc1a98088b246171515574ac8364e8436633fb5eb` | `45d6e8749eb111f2ca08934c068ebea730436253836c4a18ad4edaeec0ea6365` | `fbd0a09a1c67ddc841459c7d7a8e5da5cc34148ed5f8d6e40c2220fa30610c58` |

## 3. What this establishes

1. **The package name is stable across all three artefacts:** `com.haven.familysafety`. This is the value Firebase needs
   for an Android app registration, and it is the value the Capacitor config declares.
2. **1.1-release and 1.2-release are the same identity and the same signer.** Only the version code differs.
3. **1.0 is a different build in two material ways:** a different signing certificate (a Gujarat/India identity rather
   than `O=Haven Demo, C=US`) and a different Capacitor configuration — 1.0 loads a remote site
   (`webDir: dist`, `server.url` to a Qoder-hosted domain), while 1.1/1.2 bundle `dist-android` and use
   `androidScheme: https`. A package name alone does not make 1.0 the same distribution.

## 4. What this does not establish

- **Not an authenticity proof.** The APKs are unsigned-by-a-trusted-CA, locally built artefacts. Their digests prove the
  files were not altered between capture and this record; they do not prove who built them or that they are the binaries
  Play will serve. Per the project's standing rule, a hash and a TLS download are not authenticity.
- **Not the Play identity.** If Play App Signing is used, the certificate fingerprint in the Play Console will differ from
  both certificates above. The package name is unaffected; App Check / phone-auth setup keyed to a fingerprint is.
- **Not source-verified.** `android/app/build.gradle(.kts)` and the merged `AndroidManifest.xml` are not in this
  repository, so the source-level `applicationId` could not be compared. The binary is the authoritative shipped value;
  the source remains unchecked.
- **No Firebase action.** No project exists, no app was registered, no `google-services.json` was downloaded, no
  credential was created.

## 5. Consequence for G2

The package half of G2 is **VERIFIED for 1.1/1.2** and closed. The project-creation half remains **BLOCKED — owner
decision** (new project, project id, owner account). The 1.0 divergence is recorded so that a future upload or a
"which APK is ours" question is answered from this table rather than from the filename.

Sanitisation: certificate fingerprints and APK digests are public identifiers, not secrets; no key material, token,
service-account content or personal data appears in this file.
