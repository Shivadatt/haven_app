# Known Limitations — Phase 1 Offline Foundation

This document outlines the known behavioral boundaries and technical limitations of the Phase 1 implementation. These constraints are intentional design consequences of running in a purely offline local environment without active cloud infrastructure or native platform drivers.

---

## 1. Local Device & Telemetry Simulation

1. **Simulated Child Hardware:**
   - Devices enrolled in Phase 1 exist purely as database records within `LocalTables.devices`.
   - Device status (battery level, online state, storage capacity) is simulated and does not reflect a live physical mobile device.
2. **Deterministic Activity & Geofence Logs:**
   - Activity events, app usage metrics (`usage_daily`), and geofence crossings (`location_events`) are populated either via test fixtures, manual entry, or through the `DemoDataSuite`.
   - There is no background GPS daemon broadcasting child coordinates in real time.

---

## 2. Authentication & Security Scope

1. **Local Parent Account Only:**
   - Account credentials are stored securely on the local device via `PreferencesStore` and hashed passwords.
   - Credentials cannot be used to log in on a second physical parent device without cloud sync (deferred to Phase 2).
   - "Forgot Password" flows are limited to local reset mechanisms.
2. **Pairing Code Verification:**
   - The 6-digit pairing code workflow operates locally inside the parent app to simulate how a child device will complete the handshake in future phases.
   - Code verification occurs against the in-memory or persisted local session rather than a secure cloud key distribution center (KDC).

---

## 3. Alerts & Real-Time Notifications

1. **Local Polling & In-Memory Signals:**
   - Safety alerts displayed on the Notifications board represent records written to `TableName.safetyAlerts`.
   - Because Firebase Cloud Messaging (FCM) is deferred, incoming alerts do not trigger native operating system lock-screen push notifications while the app is closed.
2. **Local Read Acknowledgment:**
   - Marking an alert as read updates the local `acknowledged_at` and `acknowledged_by` timestamp fields. In cloud mode, this will route through service-role RPC calls once backend contracts are deployed.

---

## 4. Platform & Persistence Safeguards

1. **Storage Sandboxing:**
   - Local tables are backed by file/preference storage on the host machine. Clearing application app data in Android OS settings will wipe the local database unless a backup is restored.
2. **Demo Data Awareness:**
   - Demo records are clearly badged with a visual `DEMO` chip in the UI. If demo data is active, parent metrics shown on the dashboard aggregate both real local records and demo records. Using the "Clear Demo Data" action in Settings removes demo data immediately.

