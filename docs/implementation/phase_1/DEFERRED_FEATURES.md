# Deferred Features — Phase 1 Boundary Specification

The following features were intentionally excluded from Phase 1 according to the approved architecture roadmap and contract constraints. These capabilities belong to future backend cloud integration phases, Android native service development, or physical hardware device pairing.

---

## 1. Cloud & Backend Deferred Scope

1. **Supabase Cloud Synchronization:**
   - Real-time PostgreSQL subscriptions via WebSockets.
   - Remote database migration deployment and edge functions execution.
   - Cloud row-level security (RLS) enforcement.
2. **Firebase Cloud Messaging (FCM):**
   - Out-of-band push notification delivery to remote devices.
   - FCM registration token rotation and background push wakeups.
3. **Cloud Authentication:**
   - OAuth 2.0 / OpenID Connect providers (Google, Apple sign-in).
   - Remote JWT issuance, token refresh cycles, and cloud password resets.
4. **Multi-Parent Cloud Synchronization:**
   - Cross-device distributed family state synchronization between multiple parent devices via cloud relays.

---

## 2. Android Native & Device Enforcement Deferred Scope

1. **Physical Device Accessibility Service:**
   - Accessibility node inspection for real-time foreground app package detection.
   - On-screen overlay blocking windows (`TYPE_APPLICATION_OVERLAY`).
2. **Device Administration & Device Owner (DPM):**
   - `DevicePolicyManager` lockdown controls.
   - Hardware camera disablement, USB transfer restrictions, factory reset protection.
3. **Android VPN Website Filtering:**
   - `VpnService` TUN interface packet interception.
   - DNS filtering and SNI inspection for real-time domain blocking on physical child hardware.
4. **Background Location & Geofencing Native Services:**
   - Persistent Android foreground service with `ACCESS_BACKGROUND_LOCATION`.
   - Android Native Geofence API registering with Google Play Services.
5. **Real Physical Device Pairing:**
   - Camera-based QR code optical scanning.
   - Bluetooth Low Energy (BLE) or Wi-Fi Direct physical device discovery and key exchange.

---

## 3. Remote Streaming & Media Deferred Scope

1. **WebRTC Remote View:**
   - Remote camera live streaming.
   - Remote ambient audio recording or live microphone listening.
   - Live screen mirroring/recording stream.

All deferred capabilities are cleanly isolated behind abstract repository interfaces, allowing Phase 2 and subsequent releases to implement concrete cloud and native providers without refactoring existing UI controllers or domain models.

