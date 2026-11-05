# Modules J, K, L, M: Alerts & Activity, Permissions & Child Setup, Settings & Support, Additional Features

def register_modules_j_k_l_m(add_feature):
    # MODULE J: ALERTS AND ACTIVITY (11 features)
    add_feature(
        fid="ALRT-01",
        module="Module J: Alerts and Activity",
        name="Safety Alerts Dashboard & Unread Badge",
        expected="Central notifications and alerts screen. Displays unread badge counter in app bar; lists all safety reports recorded across family devices; supports pull-to-refresh.",
        screens="NotificationsPage (Route: '/notifications')",
        actions="Open Notifications from dashboard, view reports list, pull to refresh.",
        ui_states="Loading, Populated Reports, Empty Setup Required.",
        controller="NotificationsController (`apps/haven_app/lib/features/notifications/controllers/notifications_controller.dart`)",
        model="AlertBoard, AlertLine (`apps/haven_app/lib/features/notifications/data/alerts_models.dart`)",
        service="AlertsRepository (`apps/haven_app/lib/features/notifications/data/alerts_repository.dart`)",
        native="None",
        deps="AUTH-01, PAIR-09",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/notifications/views/pages/notifications_page.dart:12-45\napps/haven_app/lib/features/notifications/controllers/notifications_controller.dart:25-65\ntest/notifications/notifications_page_test.dart",
        missing="None for read display; backend read relies on `safety_alerts` table.",
        priority="P0",
        classification="Alerts Core"
    )

    add_feature(
        fid="ALRT-02",
        module="Module J: Alerts and Activity",
        name="Categorized Alert Feed",
        expected="Displays safety alerts categorized by kind: Safe Zone Transition, Device Tamper / Admin Removal, Screen Time Limit Reached, Blocked App Attempt, SOS Emergency.",
        screens="NotificationsPage",
        actions="Scroll alert cards, view category tag and timestamp.",
        ui_states="Cards rendered with category labels and tone chips.",
        controller="NotificationsController.board",
        model="AlertLine, AlertCategory enum",
        service="AlertsRepository.load",
        native="None",
        deps="ALRT-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/notifications/views/widgets/report_card.dart:15-85\napps/haven_app/lib/features/notifications/data/alerts_models.dart:1-95\ntest/notifications/alerts_models_test.dart",
        missing="None.",
        priority="P0",
        classification="Alerts Core"
    )

    add_feature(
        fid="ALRT-03",
        module="Module J: Alerts and Activity",
        name="Alert Detail Inspection Sheet",
        expected="Modal sheet displaying full technical payload of an alert: event trigger, device name, child name, exact coordinates if geofence, and answered status.",
        screens="NotificationsPage / AlertDetailSheet",
        actions="Tap alert card to expand details.",
        ui_states="Detail sheet open, payload key-value pairs formatted.",
        controller="NotificationsController",
        model="AlertLine, SafetyAlert (`packages/haven_models/lib/src/telemetry_models.dart`)",
        service="AlertsRepository",
        native="None",
        deps="ALRT-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/notifications/views/widgets/report_card.dart:65-86\ntest/notifications/notifications_feed_test.dart",
        missing="None.",
        priority="P0",
        classification="Alerts UX"
    )

    add_feature(
        fid="ALRT-04",
        module="Module J: Alerts and Activity",
        name="Alert Severity Level Tones",
        expected="Color-coded StatusChips reflecting severity: Critical (Red/Bad for SOS/tamper), Warning (Amber for time limits/geofence exits), Informational (Neutral/Grey for check-ins).",
        screens="NotificationsPage, DashboardPage",
        actions="Observe severity status chips.",
        ui_states="Bad (Critical), Warning (Warning), Neutral (Info).",
        controller="ReportRow._tone (`report_card.dart:91`)",
        model="AlertSeverity enum (`critical`, `warning`, `info`)",
        service="None",
        native="None",
        deps="ALRT-02",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/notifications/views/widgets/report_card.dart:90-96\ntest/notifications/reports_limits_page_test.dart",
        missing="None.",
        priority="P0",
        classification="Alerts UX"
    )

    add_feature(
        fid="ALRT-05",
        module="Module J: Alerts and Activity",
        name="Read vs Unread Visual Distinction & Filter",
        expected="Distinct visual styling for unread alerts (bold title, indicator dot); filter toggle allowing parent to switch between 'Unread' and 'All Reports'.",
        screens="NotificationsPage",
        actions="Toggle 'Unread Only' filter chip.",
        ui_states="Unread items bolded, filtered list active.",
        controller="NotificationsController.showUnreadOnly",
        model="AlertLine.answer",
        service="AlertsRepository",
        native="None",
        deps="ALRT-01",
        status="PARTIAL",
        evidence="apps/haven_app/lib/features/notifications/views/widgets/report_card.dart:36-39, 82 (shows `line.answer`; no toggle filter built).",
        missing="Unread toggle filter chip in notifications view.",
        priority="P1",
        classification="Alerts UX"
    )

    add_feature(
        fid="ALRT-06",
        module="Module J: Alerts and Activity",
        name="Mark Alert as Acknowledged / Read",
        expected="Action allowing parent to mark an alert as acknowledged, removing it from unread count and updating backend answered status.",
        screens="NotificationsPage",
        actions="Tap 'Acknowledge' button on alert card.",
        ui_states="Refusal Notice ('Nothing here can be marked... ackGap'), Updating, Marked.",
        controller="NotificationsController.ackAlert",
        model="BlockedFailure",
        service="AlertsRepository.acknowledgeAlert (`alerts_repository.dart:45-55`)",
        native="None",
        deps="ALRT-01",
        status="PLACEHOLDER",
        evidence="apps/haven_app/lib/features/notifications/views/widgets/report_card.dart:133\napps/haven_app/lib/features/notifications/data/alerts_repository.dart:45-55",
        missing="UI renders refusal `BlockedNotice` ('Nothing here can be marked... ackGap'). Acknowledge RPC not grant-accessible.",
        priority="P1",
        classification="Alert Mutation"
    )

    add_feature(
        fid="ALRT-07",
        module="Module J: Alerts and Activity",
        name="Clear Single Alert & Bulk Clear Action",
        expected="Swipe-to-dismiss gesture on individual alerts and 'Clear All' button in app bar to dismiss alerts.",
        screens="NotificationsPage",
        actions="Swipe alert card to dismiss, tap 'Clear All'.",
        ui_states="Dismissible animation, List cleared.",
        controller="NotificationsController.clearAll",
        model="Result<void>",
        service="AlertsRepository.clearAlerts",
        native="None",
        deps="ALRT-01",
        status="NOT IMPLEMENTED",
        evidence="None in frontend codebase.",
        missing="Dismissible alert card widgets, clear all action in controller.",
        priority="P2",
        classification="Alert Mutation"
    )

    add_feature(
        fid="ALRT-08",
        module="Module J: Alerts and Activity",
        name="Comprehensive Activity Timeline Feed",
        expected="Unified chronological activity feed combining all events: location changes, app launches, screen time milestones, policy changes, and tamper attempts.",
        screens="ActivityTimelinePage (New Route: '/activity/timeline')",
        actions="Scroll unified timeline, tap event to jump to relevant detail screen.",
        ui_states="Unified timeline feed with date grouping.",
        controller="ActivityTimelineController (GetxController)",
        model="TimelineEvent(id, timestamp, eventType, childName, summary, payload)",
        service="ActivityRepository, AlertsRepository, LocationRepository",
        native="None",
        deps="ALRT-02, LOC-05, APP-05",
        status="PARTIAL",
        evidence="`usage_card.dart` shows app rows; `fix_card.dart` shows location fixes; no unified timeline combining them exists.",
        missing="Unified activity timeline screen merging disparate data streams into date-grouped timeline.",
        priority="P1",
        classification="Activity Feed"
    )

    add_feature(
        fid="ALRT-09",
        module="Module J: Alerts and Activity",
        name="Activity Feed Date Range & Category Filter",
        expected="Date range picker (Today, Yesterday, Last 7 Days, Custom Date) and event type filters to filter the unified activity feed.",
        screens="ActivityTimelinePage",
        actions="Select date range, toggle category chips.",
        ui_states="Filtered feed rendered.",
        controller="ActivityTimelineController.filter",
        model="ActivityFilterCriteria",
        service="None",
        native="None",
        deps="ALRT-08",
        status="NOT IMPLEMENTED",
        evidence="None in frontend.",
        missing="Date range selector and filter predicate logic.",
        priority="P1",
        classification="Activity UX"
    )

    add_feature(
        fid="ALRT-10",
        module="Module J: Alerts and Activity",
        name="Alerts Empty State",
        expected="Friendly clean illustration when there are no reports: 'All quiet! Nothing has been reported about this family yet.'",
        screens="NotificationsPage",
        actions="View empty feed.",
        ui_states="Empty reports SectionCard.",
        controller="NotificationsController.board",
        model="AlertBoard",
        service="None",
        native="None",
        deps="ALRT-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/notifications/views/widgets/report_card.dart:25-30\napps/haven_app/lib/features/notifications/views/pages/notifications_page.dart:25-30",
        missing="None.",
        priority="P0",
        classification="Alerts UX"
    )

    add_feature(
        fid="ALRT-11",
        module="Module J: Alerts and Activity",
        name="In-App Push Notification Preferences",
        expected="Toggles allowing parent to choose which alerts trigger push notifications: Geofence Arrivals/Departures, Time Limit Reached, Tamper Alerts, Daily Summary.",
        screens="SettingsPage (Route: '/settings')",
        actions="Toggle alert notification switches on/off.",
        ui_states="Toggles active, permission status indicator.",
        controller="SettingsController.notifications (`apps/haven_app/lib/features/settings/controllers/settings_controller.dart`)",
        model="NotificationAccess enum (`granted`, `denied`, `unavailable`)",
        service="SettingsRepository (`apps/haven_app/lib/features/settings/data/settings_repository.dart`)",
        native="None",
        deps="AUTH-01, SET-05",
        status="UI ONLY",
        evidence="apps/haven_app/lib/features/settings/views/pages/settings_page.dart:60-105\ntest/settings/settings_controller_test.dart",
        missing="Push transport registration fails closed (`push_transport_impl.dart`); UI toggles present but unbacked by token push lane.",
        priority="P1",
        classification="Settings UI"
    )

    # MODULE K: PERMISSIONS AND CHILD DEVICE SETUP (13 features)
    add_feature(
        fid="PERM-01",
        module="Module K: Permissions and Child Device Setup",
        name="Permissions Setup Checklist & Master Hub",
        expected="Master permission diagnostic hub on parent settings and child device. Displays live cards for all required OS permissions, current grant status, and parental explanations.",
        screens="PermissionStatusPage (Route: '/settings/permissions')",
        actions="Open Permissions, review status of parent phone and child phone requirements.",
        ui_states="This Phone card, Paired Devices section, Permission state chips.",
        controller="SettingsController",
        model="DeviceStateReport (`apps/haven_app/lib/core/permissions/native_device_state.dart`)",
        service="SettingsRepository, NativeDeviceState",
        native="HavenBridge (`android_native/child_services/platform_bridge/HavenBridge.kt`)",
        deps="AUTH-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/settings/views/pages/permission_status_page.dart:18-95\ntest/settings/permission_status_page_test.dart",
        missing="Runtime permission request triggers in Kotlin.",
        priority="P0",
        classification="Permissions Core"
    )

    add_feature(
        fid="PERM-02",
        module="Module K: Permissions and Child Device Setup",
        name="Device Admin Activation Guide & Status Detection",
        expected="Queries `DevicePolicyManager.isAdminActive` via MethodChannel. Displays active status chip; provides guide on how Device Admin prevents uninstallation.",
        screens="PermissionStatusPage, DeviceStateCard",
        actions="Tap 'Activate Device Admin', follow OS prompt.",
        ui_states="Admin Active (good), Admin Inactive (warning), Receiver Undeclared (blocked).",
        controller="SettingsController, ChannelNativeDeviceState",
        model="DeviceAdminReport",
        service="ChannelNativeDeviceState (`apps/haven_app/lib/core/permissions/channel_device_state.dart`)",
        native="DeviceAdminStateReader (`android_native/child_services/device_admin/DeviceAdminStateReader.kt`)",
        deps="PERM-01",
        status="COMPLETE",
        evidence="android_native/child_services/device_admin/DeviceAdminStateReader.kt:25-45\napps/haven_app/lib/core/permissions/device_state_decoding.dart:50-80\napps/haven_app/lib/features/settings/views/widgets/device_state_card.dart:1-140",
        missing="Platform intent launcher to open `DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN`.",
        priority="P0",
        classification="Device Admin Core"
    )

    add_feature(
        fid="PERM-03",
        module="Module K: Permissions and Child Device Setup",
        name="Usage Access (AppOps) Authorization Guide",
        expected="Queries Android `AppOpsManager` for `OP_GET_USAGE_STATS`. Displays real OS mode ('allowed', 'ignored', 'errored', 'refused'); deep links to Android Usage Access Settings.",
        screens="PermissionStatusPage, DeviceStateCard",
        actions="Tap 'Grant Usage Access', system opens Android Settings.",
        ui_states="Allowed (green), Denied/Refused (amber/warning).",
        controller="ChannelNativeDeviceState",
        model="MonitoringReport",
        service="ChannelNativeDeviceState",
        native="MonitoringStateReader (`android_native/child_services/monitoring/MonitoringStateReader.kt:27-63`)",
        deps="PERM-01",
        status="PARTIAL",
        evidence="android_native/child_services/monitoring/MonitoringStateReader.kt:27-63\napps/haven_app/lib/core/permissions/native_device_state.dart:45-80",
        missing="Deep link platform intent from Dart to open `Settings.ACTION_USAGE_ACCESS_SETTINGS`.",
        priority="P0",
        classification="Native Diagnostics"
    )

    add_feature(
        fid="PERM-04",
        module="Module K: Permissions and Child Device Setup",
        name="Location Permission Transparency Guide",
        expected="Explains `ACCESS_FINE_LOCATION` and `ACCESS_BACKGROUND_LOCATION`; queries OS permission state; clarifies that location is collected only in foreground in baseline.",
        screens="PermissionStatusPage",
        actions="Review location transparency disclosure.",
        ui_states="Location In Use (chip), Background Location (chip).",
        controller="SettingsController",
        model="TrackedPermission enum (`OsAnswers.kt:91-96`)",
        service="ChannelNativeDeviceState",
        native="LocationStateReader (`android_native/child_services/location/LocationStateReader.kt:32-35`)",
        deps="PERM-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/settings/views/pages/permission_status_page.dart:30-40\nandroid_native/child_services/location/LocationStateReader.kt:32-35",
        missing="Runtime permission request dialog prompt in Kotlin.",
        priority="P0",
        classification="Permissions Disclosure"
    )

    add_feature(
        fid="PERM-05",
        module="Module K: Permissions and Child Device Setup",
        name="Notification Permission Probe",
        expected="Checks `POST_NOTIFICATIONS` permission (Android 13+) and notification channel importance; triggers runtime prompt if ungranted.",
        screens="PermissionStatusPage, SettingsPage",
        actions="Tap 'Allow notifications' button.",
        ui_states="Allowed (green), Not Allowed (amber), Unavailable (grey).",
        controller="SettingsController.askForNotifications",
        model="NotificationAccess enum",
        service="SettingsRepository.askForNotifications",
        native="PermissionStateReader (`android_native/child_services/permissions/PermissionStateReader.kt`)",
        deps="PERM-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/settings/views/pages/settings_page.dart:70-100\nandroid_native/child_services/platform_bridge/OsAnswers.kt:42-50\ntest/settings/settings_controller_test.dart",
        missing="None.",
        priority="P0",
        classification="Permissions Core"
    )

    add_feature(
        fid="PERM-06",
        module="Module K: Permissions and Child Device Setup",
        name="Battery Optimization (Doze) Exemption Guide",
        expected="Queries `PowerManager.isIgnoringBatteryOptimizations`; guides parent to disable Doze battery killing for continuous background protection.",
        screens="PermissionStatusPage, DeviceStateCard",
        actions="Tap 'Disable Battery Optimization', confirm prompt.",
        ui_states="Optimized (warning), Ignored/Unrestricted (good).",
        controller="ChannelNativeDeviceState",
        model="MonitoringReport.batteryOptimizationIgnored",
        service="ChannelNativeDeviceState",
        native="MonitoringStateReader (`MonitoringStateReader.kt:31-34`)",
        deps="PERM-01",
        status="PARTIAL",
        evidence="android_native/child_services/monitoring/MonitoringStateReader.kt:31-34\napps/haven_app/lib/core/permissions/device_state_decoding.dart:70-85",
        missing="Platform intent trigger for `Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`.",
        priority="P1",
        classification="Native Diagnostics"
    )

    add_feature(
        fid="PERM-07",
        module="Module K: Permissions and Child Device Setup",
        name="System Alert Window (Overlay) Setup",
        expected="Checks `Settings.canDrawOverlays`; provides walkthrough to enable overlay permission required for lockout screens when time limit is reached.",
        screens="PermissionStatusPage / OverlaySetupPage",
        actions="Tap 'Enable Overlay Permission', toggle in Android Settings.",
        ui_states="Overlay Allowed (good), Overlay Denied (warning).",
        controller="PermissionController",
        model="OverlayPermissionReport",
        service="ChannelNativeDeviceState",
        native="None (Undeclared in Manifest)",
        deps="PERM-01",
        status="NOT IMPLEMENTED",
        evidence="Undeclared in `AndroidManifest.xml` and unread in Kotlin readers.",
        missing="Manifest declaration `<uses-permission android:name=\"android.permission.SYSTEM_ALERT_WINDOW\"/>`, Kotlin reader method, and Dart decoder.",
        priority="P1",
        classification="Native Diagnostics"
    )

    add_feature(
        fid="PERM-08",
        module="Module K: Permissions and Child Device Setup",
        name="Camera & Microphone Consent Notice",
        expected="Read-only probe checking hardware presence and permissions without opening sensors; displays clear notice that mic/camera only activate upon explicit consent.",
        screens="PermissionStatusPage",
        actions="Review camera/mic privacy notes.",
        ui_states="Microphone / Camera facts card.",
        controller="ChannelNativeDeviceState",
        model="CommunicationReport",
        service="ChannelNativeDeviceState",
        native="CommunicationStateReader (`android_native/child_services/communication/CommunicationStateReader.kt:25-55`)",
        deps="PERM-01",
        status="COMPLETE",
        evidence="android_native/child_services/communication/CommunicationStateReader.kt:25-55\napps/haven_app/lib/features/settings/views/pages/permission_status_page.dart:45-50",
        missing="None.",
        priority="P0",
        classification="Privacy Compliance"
    )

    add_feature(
        fid="PERM-09",
        module="Module K: Permissions and Child Device Setup",
        name="Tri-State Permission Status Chips",
        expected="Renders exact OS status for each permission: 'Granted' (Good/Green), 'Denied' (Warning/Amber), 'Undeclared/Unavailable' (Blocked/Grey).",
        screens="PermissionStatusPage, DeviceStateCard",
        actions="Observe permission status chips.",
        ui_states="StatusChip widgets in green, amber, or grey.",
        controller="DeviceStateCard component",
        model="StatusTone enum (`neutral`, `good`, `warning`, `bad`, `blocked`)",
        service="StatusChip (`apps/haven_app/lib/shared/components/status_chip.dart`)",
        native="None",
        deps="PERM-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/settings/views/widgets/device_state_card.dart:40-95\napps/haven_app/lib/shared/components/status_chip.dart:15-35\ntest/shell/status_chip_test.dart",
        missing="None.",
        priority="P0",
        classification="UI Components"
    )

    add_feature(
        fid="PERM-10",
        module="Module K: Permissions and Child Device Setup",
        name="Child Device Setup Progress Stepper",
        expected="Step-by-step setup tracker showing overall completion percentage (e.g. '4 of 6 permissions granted') during initial child phone provisioning.",
        screens="ChildSetupProgressPage",
        actions="Grant permissions sequentially, observe progress advancing.",
        ui_states="Progress bar with percentage, checklist of permissions.",
        controller="ChildSetupController",
        model="SetupProgressModel(totalRequired, totalGranted)",
        service="ChannelNativeDeviceState",
        native="None",
        deps="PERM-01",
        status="NOT IMPLEMENTED",
        evidence="None in frontend codebase.",
        missing="Aggregate completion percentage calculator and progress bar widget.",
        priority="P1",
        classification="Setup UX"
    )

    add_feature(
        fid="PERM-11",
        module="Module K: Permissions and Child Device Setup",
        name="Refresh OS State Trigger",
        expected="Button allowing parent or child to force an immediate re-read of all Android system permissions via MethodChannel.",
        screens="PermissionStatusPage, SettingsPage",
        actions="Tap 'Refresh permissions'.",
        ui_states="Refreshing spinner, updated chips.",
        controller="SettingsController.loadDeviceState",
        model="DeviceStateReport",
        service="ChannelNativeDeviceState.read (`channel_device_state.dart:23-66`)",
        native="HavenBridge.readAll",
        deps="PERM-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/core/permissions/channel_device_state.dart:23-66\ntest/permissions/channel_device_state_test.dart",
        missing="None.",
        priority="P0",
        classification="Native Bridge"
    )

    add_feature(
        fid="PERM-12",
        module="Module K: Permissions and Child Device Setup",
        name="Deep-Link to Android System Settings",
        expected="Action button on denied permissions using platform intent to directly launch the specific Android settings screen (`openSettingsWillHelp`).",
        screens="PermissionStatusPage, DeviceStateCard",
        actions="Tap 'Open Phone Settings'.",
        ui_states="Navigating to Android OS settings.",
        controller="DevicePermissionFailure.openSettingsWillHelp",
        model="DevicePermissionFailure",
        service="PlatformBridge",
        native="None (Method missing in Kotlin)",
        deps="PERM-01",
        status="NOT IMPLEMENTED",
        evidence="`DevicePermissionFailure` in `haven_core` includes `openSettingsWillHelp` boolean, but no native launcher is wired.",
        missing="MethodChannel intent handler invoking `startActivity(Intent(Settings.ACTION_...))`.",
        priority="P0",
        classification="Platform Integration"
    )

    add_feature(
        fid="PERM-13",
        module="Module K: Permissions and Child Device Setup",
        name="Anti-Tamper Device Admin Protection Notice",
        expected="Educational screen explaining that Device Administrator privileges prevent the child from silently uninstalling Haven without parent knowledge.",
        screens="PermissionStatusPage, AboutPage",
        actions="Read anti-tamper explanation.",
        ui_states="Educational SectionCard.",
        controller="None",
        model="None (Static text)",
        service="None",
        native="DeviceAdminStateReader.kt",
        deps="PERM-02",
        status="UI ONLY",
        evidence="android_native/child_services/device_admin/DeviceAdminStateReader.kt:13-21\napps/haven_app/lib/features/settings/views/pages/about_page.dart:20-23",
        missing="Dynamic anti-tamper alert trigger.",
        priority="P1",
        classification="Compliance / Security UI"
    )

    # MODULE L: SETTINGS AND SUPPORT (15 features)
    add_feature(
        fid="SET-01",
        module="Module L: Settings and Support",
        name="Parent Profile Settings Hub",
        expected="Quick navigation tile in Settings routing to Your Account page; displays signed-in parent email and name.",
        screens="SettingsPage (Route: '/settings')",
        actions="Tap 'Your account' tile.",
        ui_states="ListTile row with chevron.",
        controller="SettingsController",
        model="None",
        service="None",
        native="None",
        deps="AUTH-13",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/settings/views/pages/settings_page.dart:115\napps/haven_app/lib/features/account/views/pages/account_page.dart:1-198",
        missing="None.",
        priority="P0",
        classification="Settings Core"
    )

    add_feature(
        fid="SET-02",
        module="Module L: Settings and Support",
        name="Family Settings Hub",
        expected="Settings entrypoint to manage family name, view members, and manage family permissions.",
        screens="SettingsPage, FamilyPage",
        actions="Navigate to Family management.",
        ui_states="SectionCard with family link.",
        controller="FamilyController",
        model="Family",
        service="FamilyRepository",
        native="None",
        deps="FAM-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/family/views/pages/family_page.dart:71-102\ntest/family/family_page_test.dart",
        missing="None.",
        priority="P0",
        classification="Settings Core"
    )

    add_feature(
        fid="SET-03",
        module="Module L: Settings and Support",
        name="Child Specific Settings Navigator",
        expected="Settings sub-menu allowing parent to select a child and configure child-level defaults (bedtime, daily limit, web filter).",
        screens="SettingsPage / ChildSettingsMenu",
        actions="Tap child name, configure child defaults.",
        ui_states="List of children tiles with chevrons.",
        controller="ChildProfileController",
        model="FamilyPerson",
        service="FamilyRepository",
        native="None",
        deps="FAM-04",
        status="PARTIAL",
        evidence="`child_profile_page.dart:1-130` exists, but has no settings configurator for limits.",
        missing="Child settings configurator sub-screen.",
        priority="P1",
        classification="Settings Navigation"
    )

    add_feature(
        fid="SET-04",
        module="Module L: Settings and Support",
        name="Device Management Settings Navigator",
        expected="Settings sub-menu listing paired devices to manage hardware telemetry, rename, or revoke.",
        screens="SettingsPage, DevicesPage",
        actions="Tap 'Paired devices' tile.",
        ui_states="ListTile row.",
        controller="DevicesController",
        model="Device",
        service="DevicesRepository",
        native="None",
        deps="PAIR-09",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/child_devices/views/pages/devices_page.dart:1-105\napps/haven_app/lib/features/child_devices/views/pages/device_detail_page.dart:1-177",
        missing="None.",
        priority="P0",
        classification="Settings Navigation"
    )

    add_feature(
        fid="SET-05",
        module="Module L: Settings and Support",
        name="Push Notification Preferences Toggles",
        expected="Interactive toggles for alert notification sounds, critical alert bypass, and daily summary push delivery.",
        screens="SettingsPage",
        actions="Toggle notification switches.",
        ui_states="Switches rendered, permission chip.",
        controller="SettingsController",
        model="NotificationPreferencesRecord",
        service="SettingsRepository",
        native="None",
        deps="ALRT-11",
        status="UI ONLY",
        evidence="apps/haven_app/lib/features/settings/views/pages/settings_page.dart:60-105\ntest/settings/settings_controller_test.dart",
        missing="Backend push token registration is blocked (`push_transport_impl.dart`).",
        priority="P1",
        classification="Settings UX"
    )

    add_feature(
        fid="SET-06",
        module="Module L: Settings and Support",
        name="App Theme Mode Selector & Persistence",
        expected="ChoiceChips allowing parent to switch between System, Light, and Dark themes; persists selection locally in `PreferencesStore`.",
        screens="SettingsPage (Route: '/settings')",
        actions="Tap 'System', 'Light', or 'Dark' chip.",
        ui_states="Selected chip highlighted, app theme updates dynamically.",
        controller="SettingsController.chooseTheme (`settings_controller.dart:35-49`)",
        model="ThemeChoice enum (`system`, `light`, `dark`)",
        service="ThemePreference (`apps/haven_app/lib/features/settings/services/theme_preference.dart:1-70`), PreferencesStore",
        native="None",
        deps="None",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/settings/views/pages/settings_page.dart:35-57\napps/haven_app/lib/features/settings/controllers/settings_controller.dart:35-49\ntest/settings/theme_preference_test.dart",
        missing="None. Fully functional and persists offline.",
        priority="P0",
        classification="Appearance / UX"
    )

    add_feature(
        fid="SET-07",
        module="Module L: Settings and Support",
        name="Application Language & Locale Selector",
        expected="Allows parent to select language (English, Spanish, French, German); updates GetX locale.",
        screens="SettingsPage / LanguageDialog",
        actions="Tap 'Language', pick locale from list, save.",
        ui_states="Language picker dialog, app re-renders in new language.",
        controller="SettingsController.chooseLanguage",
        model="Locale",
        service="PreferencesStore",
        native="None",
        deps="None",
        status="NOT IMPLEMENTED",
        evidence="All text hardcoded in English throughout repository.",
        missing="`Get.updateLocale`, arb localization files, language selector dialog.",
        priority="P2",
        classification="Localization"
    )

    add_feature(
        fid="SET-08",
        module="Module L: Settings and Support",
        name="Privacy Policy & Data Retention Viewer",
        expected="Screen or modal displaying Haven's plain-English privacy policy, COPPA/GDPR-K compliance statement, and data retention rules.",
        screens="AboutPage, PrivacyPolicyPage",
        actions="Tap 'Privacy Policy', read legal text.",
        ui_states="Document reader layout.",
        controller="None",
        model="None",
        service="None",
        native="None",
        deps="None",
        status="PARTIAL",
        evidence="apps/haven_app/lib/features/settings/views/pages/about_page.dart:19-28 (provides summary promises; full legal text missing).",
        missing="Dedicated Legal / Privacy Policy document viewer screen.",
        priority="P1",
        classification="Compliance / Legal UI"
    )

    add_feature(
        fid="SET-09",
        module="Module L: Settings and Support",
        name="Terms of Service Document Viewer",
        expected="Full Terms of Service legal agreement accessible from Settings.",
        screens="TermsOfServicePage",
        actions="Tap 'Terms of Service', read agreement.",
        ui_states="Document viewer layout.",
        controller="None",
        model="None",
        service="None",
        native="None",
        deps="None",
        status="NOT IMPLEMENTED",
        evidence="None in frontend codebase.",
        missing="Terms of Service page, route, and legal text assets.",
        priority="P2",
        classification="Compliance / Legal UI"
    )

    add_feature(
        fid="SET-10",
        module="Module L: Settings and Support",
        name="Help Center & Troubleshooting Hub",
        expected="Directory of troubleshooting topics (e.g. 'Child phone not updating location', 'Time limits not applying', 'Pairing code failed').",
        screens="HelpCenterPage (New Route: '/support/help')",
        actions="Search help topics, tap article to expand solution.",
        ui_states="Category cards, searchable article list.",
        controller="HelpCenterController",
        model="HelpArticle(title, body, tags)",
        service="None",
        native="None",
        deps="None",
        status="NOT IMPLEMENTED",
        evidence="None in frontend codebase.",
        missing="Help center page, article cards, troubleshooting tree.",
        priority="P2",
        classification="Support UX"
    )

    add_feature(
        fid="SET-11",
        module="Module L: Settings and Support",
        name="FAQ Accordion Viewer",
        expected="Expandable accordion list of common parental questions and answers.",
        screens="FAQPage",
        actions="Tap FAQ tile to expand answer.",
        ui_states="Accordion list with animated expand/collapse.",
        controller="FAQController",
        model="FAQItem(question, answer)",
        service="None",
        native="None",
        deps="SET-10",
        status="NOT IMPLEMENTED",
        evidence="None in frontend.",
        missing="FAQ page with ExpansionPanelList or custom accordion tiles.",
        priority="P2",
        classification="Support UX"
    )

    add_feature(
        fid="SET-12",
        module="Module L: Settings and Support",
        name="Contact Support & Diagnostic Mailer",
        expected="Form allowing parent to contact support, submit feedback, or bundle anonymized diagnostic logs (OS version, backend readiness).",
        screens="ContactSupportPage",
        actions="Type support message, attach diagnostic logs, tap 'Send'.",
        ui_states="Feedback Form, Sending Busy, Sent Confirmation.",
        controller="ContactSupportController",
        model="SupportTicket(subject, body, diagnosticReport)",
        service="UrlLauncher / DiagnosticService",
        native="None",
        deps="SET-10",
        status="NOT IMPLEMENTED",
        evidence="None in frontend.",
        missing="Feedback form, email intent dispatcher (`url_launcher`).",
        priority="P2",
        classification="Support UX"
    )

    add_feature(
        fid="SET-13",
        module="Module L: Settings and Support",
        name="About Haven Screen",
        expected="Displays app name, description, core architectural promises, and connectivity status.",
        screens="AboutPage (Route: '/settings/about')",
        actions="Open About Haven, read architectural promises.",
        ui_states="About Card, Promises Card, Connectivity Status Card.",
        controller="None (Stateless page reading HavenConfig)",
        model="HavenConfig, BackendStatus",
        service="HavenConfig (`apps/haven_app/lib/core/constants/haven_config.dart`)",
        native="None",
        deps="AUTH-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/settings/views/pages/about_page.dart:13-85\ntest/settings/about_page_test.dart",
        missing="None.",
        priority="P0",
        classification="Informational UI"
    )

    add_feature(
        fid="SET-14",
        module="Module L: Settings and Support",
        name="App Version & Build Configuration Inspector",
        expected="Shows build version (`v1.0.0+1`), release channel (`staging`/`production`), and exact missing `--dart-define` keys.",
        screens="AboutPage",
        actions="Inspect build channel and missing defines.",
        ui_states="StatusChip ('Not connected', 'Connected to staging'), missing defines list.",
        controller="None",
        model="HavenConfig.status",
        service="HavenConfig",
        native="None",
        deps="SET-13",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/settings/views/pages/about_page.dart:87-145\napps/haven_app/lib/core/constants/haven_config.dart:1-90",
        missing="None.",
        priority="P0",
        classification="Diagnostics"
    )

    add_feature(
        fid="SET-15",
        module="Module L: Settings and Support",
        name="Global User Logout Trigger",
        expected="Accessible from Settings and Account; wipes secure vault credentials, flushes cached state, and redirects to `/sign-in`.",
        screens="SettingsPage, AccountPage",
        actions="Tap 'Sign out', confirm in modal sheet.",
        ui_states="Confirmation Sheet Active, Signing Out, Redirection.",
        controller="AccountController.signOut",
        model="Result<void>",
        service="AuthRepository.signOut",
        native="None",
        deps="AUTH-18",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/account/controllers/account_controller.dart:65-75\napps/haven_app/lib/features/authentication/data/auth_repository.dart:72\ntest/account/account_page_test.dart",
        missing="None.",
        priority="P0",
        classification="Auth Flow"
    )

    # MODULE M: ADDITIONAL REQUIRED PRODUCT FEATURES (10 features)
    add_feature(
        fid="FEAT-01",
        module="Module M: Additional Required Product Features",
        name="Real-Time Geofence Entry/Exit Alert Banner",
        expected="Push notification and in-app animated banner whenever child crosses a safe-zone boundary ('Leo entered School at 8:30 AM').",
        screens="DashboardPage, SafeZonesPage, Top Toast",
        actions="Tap geofence banner to view child location on map.",
        ui_states="Dismissible in-app banner with school/home icon.",
        controller="NotificationsController, GeofenceAlertService",
        model="BlockedFailure, GeofenceAlertPayload",
        service="AlertDelivery (`apps/haven_app/lib/features/notifications/services/alert_delivery.dart`)",
        native="None",
        deps="LOC-07, ALRT-01",
        status="PLACEHOLDER",
        evidence="apps/haven_app/lib/features/notifications/views/widgets/report_card.dart:90-95\napps/haven_app/lib/features/location/data/location_repository.dart:65-72",
        missing="Real-time trigger blocked by `safe_zone_states` deny-all RLS policy; local mock banner passing.",
        priority="P0",
        classification="Geofence Alerts"
    )

    add_feature(
        fid="FEAT-02",
        module="Module M: Additional Required Product Features",
        name="Device Tamper Alert Notification",
        expected="High-priority critical alert generated when child attempts to revoke Device Admin, revoke Usage Access, or disable GPS.",
        screens="NotificationsPage, DashboardPage",
        actions="Tap tamper alert to view device recovery guidance.",
        ui_states="Critical Red Alert Card with alarm icon.",
        controller="NotificationsController",
        model="AlertLine, AlertSeverity.critical",
        service="AlertsRepository",
        native="HavenDeviceAdminReceiver (`HavenDeviceAdminReceiver.kt`)",
        deps="ALRT-01, PERM-02",
        status="PARTIAL",
        evidence="android_native/child_services/device_admin/HavenDeviceAdminReceiver.kt\napps/haven_app/lib/features/notifications/views/widgets/report_card.dart:91-95",
        missing="Native Kotlin broadcast receiver triggering tamper event telemetry payload.",
        priority="P0",
        classification="Anti-Tamper Security"
    )

    add_feature(
        fid="FEAT-03",
        module="Module M: Additional Required Product Features",
        name="Child App Uninstallation Protection UI",
        expected="Screen explaining Device Admin lock on child phone; prevents uninstallation without parent password/PIN.",
        screens="ChildAppAdminWarningPage",
        actions="Child attempts uninstallation, system displays warning.",
        ui_states="Warning modal dialog on child device.",
        controller="DeviceAdminController",
        model="DeviceAdminReport",
        service="ChannelNativeDeviceState",
        native="DeviceAdminStateReader.kt",
        deps="PERM-02",
        status="PLACEHOLDER",
        evidence="android_native/child_services/device_admin/DeviceAdminStateReader.kt:38-42",
        missing="Native DevicePolicyManager `onDisableRequested` warning prompt in Kotlin.",
        priority="P1",
        classification="Anti-Tamper Security"
    )

    add_feature(
        fid="FEAT-04",
        module="Module M: Additional Required Product Features",
        name="Child Emergency SOS / Panic Button Trigger",
        expected="Prominent SOS button on child app allowing immediate distress beacon broadcast with high-priority GPS fix even if screen is locked.",
        screens="ChildDashboardPage / ChildSOSPage",
        actions="Child holds SOS button for 3 seconds, triggers beacon.",
        ui_states="3-second countdown hold animation, Beacon Dispatched State.",
        controller="ChildSOSController",
        model="SOSBeaconPayload(childId, lat, lng, timestamp)",
        service="SOSService",
        native="FusedLocationProviderClient / Intent",
        deps="LOC-01, ALRT-01",
        status="NOT IMPLEMENTED",
        evidence="None in frontend.",
        missing="Child app SOS trigger widget, emergency intent dispatcher.",
        priority="P0",
        classification="Emergency SOS"
    )

    add_feature(
        fid="FEAT-05",
        module="Module M: Additional Required Product Features",
        name="Parent SOS Distress Alert Banner & Audio Siren",
        expected="Overriding fullscreen critical banner on parent device when SOS triggered, with audible siren sound and instant navigation to child location.",
        screens="ParentSOSAlertModal / FullscreenAlarmPage",
        actions="Tap 'Mute Siren', tap 'Navigate to Child', tap 'Call Emergency Services'.",
        ui_states="Fullscreen Red Flashing Alarm, Audio Siren Playing, Location Map Pin.",
        controller="ParentSOSController",
        model="SOSAlertRecord",
        service="AudioAlarmPlayer / NotificationService",
        native="None",
        deps="FEAT-04, LOC-01",
        status="NOT IMPLEMENTED",
        evidence="None in frontend.",
        missing="SOS alarm audio player, overriding fullscreen banner modal.",
        priority="P0",
        classification="Emergency SOS"
    )

    add_feature(
        fid="FEAT-06",
        module="Module M: Additional Required Product Features",
        name="Offline Data Queue & Cloud Sync Status Indicator",
        expected="Status pill showing count of pending local mutations queued offline ('3 changes pending sync') with manual 'Sync Now' button.",
        screens="HavenScaffold, SettingsPage",
        actions="Tap sync pill, view pending items list, tap 'Sync Now'.",
        ui_states="Sync Pill ('Offline - 3 pending'), Syncing Spinner, Synced Checkmark.",
        controller="OfflineQueueController",
        model="QueuedMutationRecord(id, endpoint, payload, createdAt)",
        service="OfflineQueueService",
        native="None",
        deps="None",
        status="NOT IMPLEMENTED",
        evidence="None in frontend.",
        missing="Offline mutation queue store (`OfflineQueueService`), sync worker, and UI sync badge.",
        priority="P1",
        classification="Offline Architecture"
    )

    add_feature(
        fid="FEAT-07",
        module="Module M: Additional Required Product Features",
        name="Security & Administrative Audit Log Explorer",
        expected="Read-only searchable log of administrative actions taken by parents (policy changes, device additions, remote sessions, safe zone edits).",
        screens="AuditLogPage (New Route: '/settings/audit-logs')",
        actions="Scroll audit log, search by action type or actor, export CSV.",
        ui_states="Audit Log List with timestamps and actor tags.",
        controller="AuditLogController",
        model="AuditLogRecord (`packages/haven_models/lib/src/telemetry_models.dart`)",
        service="TelemetryRepository (`apps/haven_app/lib/features/telemetry/data/telemetry_repository.dart`)",
        native="None",
        deps="AUTH-01",
        status="PARTIAL",
        evidence="Table `audit_logs` exists in backend schema; `telemetry_repository.dart` reads audit rows.",
        missing="Dedicated UI audit log explorer screen with search and export.",
        priority="P1",
        classification="Audit Logging"
    )

    add_feature(
        fid="FEAT-08",
        module="Module M: Additional Required Product Features",
        name="Role-Based Child Dashboard View",
        expected="When child signs in or switches to child view, app renders child-friendly dashboard showing remaining screen time and active safe zones.",
        screens="ChildDashboardPage (New Route: '/child/dashboard')",
        actions="Child views remaining daily time, views allowed apps list.",
        ui_states="Child-friendly simplified card layout.",
        controller="ChildDashboardController",
        model="ChildDashboardSummary",
        service="None",
        native="None",
        deps="AUTH-13",
        status="NOT IMPLEMENTED",
        evidence="`account_page.dart:108` has `ProfileRole.child`, but routes to parent dashboard.",
        missing="Child dashboard page (`ChildDashboardPage`), child navigation shell.",
        priority="P1",
        classification="Role-Based UI"
    )

    add_feature(
        fid="FEAT-09",
        module="Module M: Additional Required Product Features",
        name="Biometric / Master PIN App Lock",
        expected="Prompts for Fingerprint/FaceID or 4-digit PIN before allowing parent to access critical settings or change limits.",
        screens="AppLockModal / BiometricPrompt",
        actions="Authenticate with fingerprint or PIN to unlock settings.",
        ui_states="Lock Overlay Active, Biometric Prompt, Unlocked.",
        controller="AppLockController",
        model="AppLockSettings(isEnabled, pinHash)",
        service="LocalAuthService (`local_auth`)",
        native="BiometricManager",
        deps="SET-01",
        status="NOT IMPLEMENTED",
        evidence="None in frontend.",
        missing="`local_auth` integration, biometric lock guard in GetX middleware.",
        priority="P2",
        classification="App Security"
    )

    add_feature(
        fid="FEAT-10",
        module="Module M: Additional Required Product Features",
        name="Device Network Connectivity Status Indicator",
        expected="Displays connection transport (WiFi SSID, Cellular 4G/5G, No Signal) reported by child device in device detail card.",
        screens="DeviceDetailPage, TelemetryCard",
        actions="Observe network status badge.",
        ui_states="WiFi connected with SSID, Mobile data with carrier, No connection.",
        controller="TelemetryController (`apps/haven_app/lib/features/telemetry/controllers/telemetry_controller.dart`)",
        model="DeviceTelemetry (`packages/haven_models/lib/src/telemetry_models.dart`)",
        service="TelemetryRepository (`apps/haven_app/lib/features/telemetry/data/telemetry_repository.dart`)",
        native="None",
        deps="PAIR-10",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/telemetry/views/widgets/trail_card.dart:1-90\npackages/haven_models/lib/src/telemetry_models.dart:1-80\ntest/telemetry/telemetry_card_test.dart",
        missing="None.",
        priority="P1",
        classification="Telemetry"
    )

print("Modules J, K, L, M registered.")
