# Modules D, E, F: Device Pairing & Management, Parent Dashboard, Location & Safe Zones

def register_modules_d_e_f(add_feature):
    # MODULE D: DEVICE PAIRING AND MANAGEMENT (16 features)
    add_feature(
        fid="PAIR-01",
        module="Module D: Device Pairing and Management",
        name="Add Device Initiation & Overview",
        expected="Parent initiates device linking from Dashboard or Devices screen. Overview page explains the two supported pairing flows: short code shown on child device, or invite sent to child ID. Clarifies that child must approve on their own device.",
        screens="PairingPage (Route: '/pairing')",
        actions="Tap 'Add Device', read pairing explanation, tap 'How pairing works'.",
        ui_states="Loading, Pairing Board Loaded, Empty Setup Required.",
        controller="PairingController (`apps/haven_app/lib/features/device_pairing/controllers/pairing_controller.dart`)",
        model="PairingBoard (`apps/haven_app/lib/features/device_pairing/data/pairing_models.dart`)",
        service="PairingRepository (`apps/haven_app/lib/features/device_pairing/data/pairing_repository.dart`)",
        native="None",
        deps="AUTH-01, ONBD-04",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/device_pairing/views/pages/pairing_page.dart:65-90\napps/haven_app/lib/features/child_devices/views/pages/devices_page.dart:81-104\ntest/device_pairing/pairing_page_test.dart",
        missing="None for overview presentation; underlying mutations blocked at seam.",
        priority="P0",
        classification="Pairing UI"
    )

    add_feature(
        fid="PAIR-02",
        module="Module D: Device Pairing and Management",
        name="6-Digit Pairing PIN Generation & Display",
        expected="Generates a 6-digit cryptographic pairing PIN (e.g. '482 910') on the parent app. Formatted with space separator; displays copy button; expires after 15 minutes; child enters this PIN on their device to establish link.",
        screens="PairingCodePage (Route: '/pairing/code')",
        actions="Generate code, view 6-digit PIN, tap 'Copy Code'.",
        ui_states="Refusal Notice ('pairing slug undeployed... PAIRING_HASH_PEPPER secret uncreated'), PIN Generated, Expired.",
        controller="PairingCodeController (`apps/haven_app/lib/features/device_pairing/controllers/pairing_code_controller.dart`)",
        model="BlockedFailure, PairingTokenRecord",
        service="PairingRepository.createInvite, EdgeCaller (`pairing/issuance`)",
        native="None",
        deps="PAIR-01",
        status="PLACEHOLDER",
        evidence="apps/haven_app/lib/features/device_pairing/views/pages/pairing_code_page.dart:50-60\napps/haven_app/lib/features/device_pairing/data/pairing_repository.dart:103-107",
        missing="UI currently renders refusal `BlockedNotice` ('pairing slug undeployed'). PIN generation UI widget, copy button, and Edge Function invocation missing.",
        priority="P0",
        classification="Pairing Flow"
    )

    add_feature(
        fid="PAIR-03",
        module="Module D: Device Pairing and Management",
        name="Pairing QR Code Generator & Display",
        expected="Generates dynamic high-density QR code on parent device containing encrypted pairing token, family ID, and relay URL. Child scans with child app camera to pair instantly without typing.",
        screens="PairingQRCodePage / QRCodeDialog",
        actions="Select 'Show QR Code', display code to child, regenerate if expired.",
        ui_states="QR Code Visible, QR Refreshing, QR Expired Overlay.",
        controller="PairingCodeController",
        model="PairingQrPayload(familyId, token, expiresAt)",
        service="PairingRepository",
        native="None",
        deps="PAIR-02",
        status="NOT IMPLEMENTED",
        evidence="None in frontend codebase.",
        missing="QR code rendering widget (`qr_flutter`), QR payload serializer, and UI dialog.",
        priority="P1",
        classification="Pairing Flow"
    )

    add_feature(
        fid="PAIR-04",
        module="Module D: Device Pairing and Management",
        name="Manual Pairing Code / Child ID Entry Form",
        expected="Alternative pairing direction: child app generates code, parent types it into a 6-cell PIN input field on parent phone, validating against pending requests.",
        screens="PairingCodePage (Route: '/pairing/code')",
        actions="Enter 6-digit code from child phone, tap 'Link Device'.",
        ui_states="Refusal Notice ('An invite for a Child ID... blocked'), 6-cell PinInput, Submitting, Success.",
        controller="PairingCodeController.codeGap",
        model="BlockedFailure",
        service="PairingRepository.redeemCode",
        native="None",
        deps="PAIR-01",
        status="PLACEHOLDER",
        evidence="apps/haven_app/lib/features/device_pairing/views/pages/pairing_code_page.dart:62-72\napps/haven_app/lib/features/device_pairing/data/pairing_repository.dart:109-115",
        missing="UI renders `BlockedNotice` refusal. 6-cell PinInput widget, form submission handler, and redeem RPC client missing.",
        priority="P0",
        classification="Pairing Flow"
    )

    add_feature(
        fid="PAIR-05",
        module="Module D: Device Pairing and Management",
        name="Pairing PIN Countdown Timer & Auto-Refresh",
        expected="Visual 15-minute countdown clock ('Valid for 14:45') shown during active pairing session. Displays circular progress arc; prompts parent to generate a fresh code when countdown reaches 0:00.",
        screens="PairingCodePage",
        actions="Observe timer countdown, tap 'Generate New Code' upon expiry.",
        ui_states="Counting Down, Urgent Warning (< 2 mins), Expired.",
        controller="PairingCodeController.timeRemaining",
        model="Duration, RxInt",
        service="Clock (`packages/haven_core/lib/src/clock.dart`)",
        native="None",
        deps="PAIR-02",
        status="NOT IMPLEMENTED",
        evidence="`pairing/issuance.ts:75` defines 15-minute TTL, but frontend has no timer widget or controller countdown.",
        missing="Countdown timer controller, progress arc painter, expiry trigger.",
        priority="P1",
        classification="Pairing UX"
    )

    add_feature(
        fid="PAIR-06",
        module="Module D: Device Pairing and Management",
        name="Pairing Status Polling & Progress State",
        expected="Displays real-time status of pending pairing requests: 'Waiting for child phone to connect', 'Code entered, linking...', 'Device paired successfully'. Automatically polls or subscribes to Realtime updates.",
        screens="PairingPage",
        actions="View pending requests list, tap request to check status.",
        ui_states="Pending Request Card, In-Flight Handshake Spinner, Failed/Cancelled.",
        controller="PairingController.board",
        model="PairingRequestLine, PairingRequestStatus",
        service="PairingRepository.load, ChangeFeed",
        native="None",
        deps="PAIR-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/device_pairing/views/widgets/requests_card.dart:1-85\napps/haven_app/lib/features/device_pairing/views/pages/pairing_page.dart:49-54\ntest/device_pairing/pairing_page_test.dart",
        missing="Realtime channel subscription for live updates; polling and offline mock verified.",
        priority="P0",
        classification="Pairing UI"
    )

    add_feature(
        fid="PAIR-07",
        module="Module D: Device Pairing and Management",
        name="Pairing Success Screen",
        expected="Celebratory screen confirming child device is linked. Displays device model ('Google Pixel 7'), child name, battery percentage, OS version, and button to open Device Dashboard.",
        screens="PairingSuccessPage (New Route: '/pairing/success')",
        actions="View linked device summary, tap 'Open Device Controls'.",
        ui_states="Success Animation, Device Specs Summary, CTA button.",
        controller="PairingController",
        model="Device (`packages/haven_models/lib/src/device_models.dart`)",
        service="None",
        native="None",
        deps="PAIR-06",
        status="NOT IMPLEMENTED",
        evidence="None (pairing redirects directly or refreshes request list).",
        missing="Dedicated Pairing Success celebration page and device specs summary card.",
        priority="P1",
        classification="Pairing UX"
    )

    add_feature(
        fid="PAIR-08",
        module="Module D: Device Pairing and Management",
        name="Pairing Failure & Rate Limit Alert",
        expected="Displays informative error card when pairing fails: invalid code, expired code, or when the 4-failure rate-limiting security window is tripped ('Too many failed attempts. Try again in 15 minutes').",
        screens="PairingPage, PairingCodePage",
        actions="View failure reason, retry pairing.",
        ui_states="Error banner in red with specific reason.",
        controller="PairingController.message, FailureMapper",
        model="HavenFailure, ValidationFailure",
        service="FailureMapper",
        native="None",
        deps="PAIR-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/device_pairing/controllers/pairing_controller.dart:60-70\napps/haven_app/lib/features/device_pairing/views/pages/pairing_page.dart:23-30\ntest/device_pairing/pairing_controller_test.dart",
        missing="None.",
        priority="P0",
        classification="Pairing UX"
    )

    add_feature(
        fid="PAIR-09",
        module="Module D: Device Pairing and Management",
        name="Paired Devices Directory List",
        expected="List of all devices paired to the family. Shows device nickname/model, assigned child, online/offline status chip, battery percentage, and navigation to device detail. Empty state provides pairing CTA.",
        screens="DevicesPage (Route: '/devices')",
        actions="Scroll devices list, tap device row to view detail, pull to refresh.",
        ui_states="Loading, Populated List, Empty Paired Devices ('No device is paired yet').",
        controller="DevicesController (`apps/haven_app/lib/features/child_devices/controllers/devices_controller.dart`)",
        model="Device (`packages/haven_models/lib/src/device_models.dart`)",
        service="DevicesRepository (`apps/haven_app/lib/features/child_devices/data/devices_repository.dart`)",
        native="None",
        deps="AUTH-01, ONBD-04",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/child_devices/views/pages/devices_page.dart:40-57\napps/haven_app/lib/features/child_devices/views/widgets/device_list_card.dart:1-95\ntest/child_devices/devices_page_test.dart",
        missing="In live environment, blocked by F6 grant wall (no SELECT on `devices` for authenticated); offline mock passes 100%.",
        priority="P0",
        classification="Device UI"
    )

    add_feature(
        fid="PAIR-10",
        module="Module D: Device Pairing and Management",
        name="Device Detail Inspector",
        expected="Detailed hardware and OS inspector for a selected child device: manufacturer, model, Android OS release, API level, enrolled date, unique device ID, and sub-report links.",
        screens="DeviceDetailPage (Route: '/devices/detail')",
        actions="Open device detail, view hardware specs, navigate to sub-reports.",
        ui_states="Loading, Device Record Card Loaded, No Device Named Fallback.",
        controller="DeviceDetailController (`apps/haven_app/lib/features/child_devices/controllers/device_detail_controller.dart`)",
        model="Device, DeviceRouteArgs (`apps/haven_app/lib/features/child_devices/data/device_route_args.dart`)",
        service="DevicesRepository.loadDevice",
        native="None",
        deps="PAIR-09",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/child_devices/views/pages/device_detail_page.dart:53-76\ntest/child_devices/device_detail_page_test.dart",
        missing="Blocked by F6 grant wall in staging; offline mock passes.",
        priority="P0",
        classification="Device UI"
    )

    add_feature(
        fid="PAIR-11",
        module="Module D: Device Pairing and Management",
        name="Device Connectivity & Last Active Formatter",
        expected="Translates `devices.last_seen_at` timestamp into relative human-readable status: 'Active now' (< 5m), 'Active 20m ago', 'Offline since yesterday'. Updates status chip tone dynamically.",
        screens="DevicesPage, DeviceDetailPage, DashboardPage",
        actions="Observe status chips.",
        ui_states="Good/Green (active now), Warning/Amber (< 24h), Neutral/Grey (> 24h).",
        controller="Time formatting utilities",
        model="DateTime lastSeenAt",
        service="HavenTime (`apps/haven_app/lib/core/utils/haven_time.dart`), duration_format (`packages/haven_core/lib/src/duration_format.dart`)",
        native="None",
        deps="None",
        status="COMPLETE",
        evidence="packages/haven_core/lib/src/duration_format.dart:1-50\napps/haven_app/lib/core/utils/haven_time.dart:1-60\ntest/core/haven_time_test.dart",
        missing="None.",
        priority="P0",
        classification="UI Formatting"
    )

    add_feature(
        fid="PAIR-12",
        module="Module D: Device Pairing and Management",
        name="Device Battery & Power Indicator",
        expected="Displays child device battery level percentage (0-100%) with dynamic battery icon (full, half, low) and charging bolt indicator. Flags red warning when child battery falls below 15%.",
        screens="DevicesPage, DeviceDetailPage, DashboardPage",
        actions="View battery level.",
        ui_states="Normal (> 20%), Low Battery Alert (< 15%), Charging Active.",
        controller="DevicesController, TelemetryController",
        model="DeviceTelemetryRecord(batteryLevel, isCharging)",
        service="TelemetryRepository (`apps/haven_app/lib/features/telemetry/data/telemetry_repository.dart`)",
        native="None",
        deps="PAIR-09",
        status="NOT IMPLEMENTED",
        evidence="Native Kotlin reads battery facts, but Flutter frontend has no battery gauge widget or battery model field.",
        missing="Battery percentage field in `Device` model, battery gauge UI widget, low battery alert trigger.",
        priority="P1",
        classification="Telemetry UI"
    )

    add_feature(
        fid="PAIR-13",
        module="Module D: Device Pairing and Management",
        name="Device Rename Dialog & Custom Labeling",
        expected="Dialog allowing parent to set a custom nickname for a device (e.g. 'Leo’s School Phone') instead of the raw manufacturer model name.",
        screens="DeviceDetailPage / RenameDeviceDialog",
        actions="Tap edit icon next to device name, enter nickname, save.",
        ui_states="Dialog Active, Saving, Updated.",
        controller="DeviceDetailController",
        model="Device",
        service="DevicesRepository.updateNickname",
        native="None",
        deps="PAIR-10",
        status="NOT IMPLEMENTED",
        evidence="None in `devices_repository.dart` or `device_detail_page.dart`.",
        missing="Rename dialog, repository mutator method, and backend UPDATE grant.",
        priority="P1",
        classification="Device Mutation"
    )

    add_feature(
        fid="PAIR-14",
        module="Module D: Device Pairing and Management",
        name="Device Unlink / Revoke Confirmation Flow",
        expected="Destructive action in Device Detail to unlink and revoke a device. Warns parent that all tracking will cease; confirms with modal sheet; triggers device revocation in backend.",
        screens="DeviceDetailPage (Route: '/devices/detail')",
        actions="Tap 'Revoke device', read warning, tap 'Confirm Revoke'.",
        ui_states="Refusal Notice ('Blocked by RPC grant wall'), Confirmation Sheet, Revoking Busy, Success.",
        controller="DeviceDetailController.revokeGap",
        model="BlockedFailure",
        service="DevicesRepository.revokeDevice (`devices_repository.dart:46-53`)",
        native="None",
        deps="PAIR-10",
        status="PLACEHOLDER",
        evidence="apps/haven_app/lib/features/child_devices/views/pages/device_detail_page.dart:142-159\napps/haven_app/lib/features/child_devices/data/devices_repository.dart:46-53",
        missing="UI renders `BlockedNotice` refusal ('revoke_device blocked by RPC grant wall'). Executable mutation client missing.",
        priority="P0",
        classification="Device Mutation"
    )

    add_feature(
        fid="PAIR-15",
        module="Module D: Device Pairing and Management",
        name="Device Reconnect & Telemetry Sync Trigger",
        expected="Action allowing parent to request an immediate telemetry refresh and policy re-evaluation from child device via push notification command.",
        screens="DeviceDetailPage",
        actions="Tap 'Ask device to re-check rules'.",
        ui_states="Refusal Notice ('request_device_recovery unexecuted'), Command Sent Toast, Response Pending.",
        controller="DeviceDetailController.recoveryGap",
        model="BlockedFailure",
        service="DevicesRepository.requestRecovery (`devices_repository.dart:55-65`)",
        native="None",
        deps="PAIR-10",
        status="PLACEHOLDER",
        evidence="apps/haven_app/lib/features/child_devices/views/pages/device_detail_page.dart:154-156\napps/haven_app/lib/features/child_devices/data/devices_repository.dart:55-65",
        missing="UI renders `BlockedNotice` refusal ('request_device_recovery unexecuted'). Push command dispatch lane missing.",
        priority="P1",
        classification="Device Mutation"
    )

    add_feature(
        fid="PAIR-16",
        module="Module D: Device Pairing and Management",
        name="Step-by-Step Child Device Pairing Guide",
        expected="Educational guidance section on `/pairing/code` explaining child phone physical consent, Wi-Fi connectivity requirements, and order of setup steps.",
        screens="PairingCodePage (Route: '/pairing/code')",
        actions="Scroll through pairing rules and requirements.",
        ui_states="Card with clear bullet points.",
        controller="PairingCodeController",
        model="None (Static guidance)",
        service="None",
        native="None",
        deps="PAIR-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/device_pairing/views/pages/pairing_code_page.dart:50-80\ntest/device_pairing/pairing_code_page_test.dart",
        missing="None.",
        priority="P1",
        classification="Instructional UI"
    )

    # MODULE E: PARENT DASHBOARD (13 features)
    add_feature(
        fid="DASH-01",
        module="Module E: Parent Dashboard",
        name="Dashboard Scaffold & Overview Layout",
        expected="Main executive parent home screen. Displays Haven app bar, family name header, member count subtitle, pull-to-refresh container, and structured card sections. Clean single-accent flat design.",
        screens="DashboardPage (Route: '/dashboard')",
        actions="Launch app into dashboard, scroll sections, tap quick action buttons.",
        ui_states="Loading, Populated Dashboard, Needs Setup Fallback.",
        controller="DashboardController (`apps/haven_app/lib/features/dashboard/controllers/dashboard_controller.dart`)",
        model="DashboardData (`apps/haven_app/lib/features/dashboard/data/dashboard_repository.dart`)",
        service="DashboardRepository",
        native="None",
        deps="AUTH-01, FAM-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/dashboard/views/pages/dashboard_page.dart:18-62\napps/haven_app/lib/features/dashboard/controllers/dashboard_controller.dart:25-75\ntest/dashboard/dashboard_page_test.dart",
        missing="None.",
        priority="P0",
        classification="Dashboard Core"
    )

    add_feature(
        fid="DASH-02",
        module="Module E: Parent Dashboard",
        name="Child Summary Card",
        expected="High-level card per child displaying avatar, display name, assigned devices count, today's screen time summary, and last known location with direct tap to child profile.",
        screens="DashboardPage",
        actions="Tap child card to navigate to child profile.",
        ui_states="Populated with children, empty children line ('No children are in this family yet').",
        controller="DashboardController.data",
        model="FamilyBundle, FamilyPerson",
        service="DashboardRepository.load",
        native="None",
        deps="DASH-01, FAM-02",
        status="PARTIAL",
        evidence="apps/haven_app/lib/features/family/views/widgets/people_card.dart:15-80\napps/haven_app/lib/features/dashboard/views/pages/dashboard_page.dart:84-93",
        missing="Card currently displays name and member facts; child screen time and location metrics are separate cards rather than aggregated into the child summary card.",
        priority="P0",
        classification="Dashboard Core"
    )

    add_feature(
        fid="DASH-03",
        module="Module E: Parent Dashboard",
        name="Device Connectivity & Last Active Badge",
        expected="Displays connectivity status of child devices directly on dashboard with real-time green/grey status chips and relative last seen timestamp.",
        screens="DashboardPage",
        actions="Observe device status chips, tap to open devices list.",
        ui_states="Connected chip (green), Disconnected chip (grey), Refusal notice if read blocked.",
        controller="DashboardController.deviceGap",
        model="BlockedFailure",
        service="DashboardRepository.deviceGap",
        native="None",
        deps="DASH-01, PAIR-11",
        status="UI ONLY",
        evidence="apps/haven_app/lib/features/dashboard/views/pages/dashboard_page.dart:130-158\napps/haven_app/lib/features/dashboard/data/dashboard_repository.dart:50-65",
        missing="Blocked by F6 grant wall on live database; renders `BlockedNotice` refusal in live staging.",
        priority="P0",
        classification="Dashboard UI"
    )

    add_feature(
        fid="DASH-04",
        module="Module E: Parent Dashboard",
        name="Child Location Summary Card",
        expected="Dashboard card summarizing child's latest reported location, accuracy, and age of fix with button to open full map view.",
        screens="DashboardPage",
        actions="Tap 'Open Safe Places' button to view safe zones and locations.",
        ui_states="Location fix card with coordinates/age, or empty note.",
        controller="DashboardController.goToSafeZones",
        model="FixBoard, ZoneBoard",
        service="DashboardRepository.load",
        native="None",
        deps="DASH-01, LOC-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/dashboard/views/widgets/safe_places_card.dart:1-70\napps/haven_app/lib/features/dashboard/views/pages/dashboard_page.dart:96\ntest/dashboard/dashboard_page_test.dart",
        missing="Mini-map preview widget on dashboard.",
        priority="P0",
        classification="Dashboard UI"
    )

    add_feature(
        fid="DASH-05",
        module="Module E: Parent Dashboard",
        name="Daily Screen Time Summary Widget",
        expected="Visual circular progress or bar gauge showing child's used screen time today vs allowed daily quota (e.g. '2h 15m / 3h 00m') with percentage filled.",
        screens="DashboardPage",
        actions="Observe screen time progress, tap to open screen time management.",
        ui_states="Screen time gauge with hours/minutes, Limit reached warning color.",
        controller="DashboardController",
        model="UsageBoard (`apps/haven_app/lib/features/device_activity/data/activity_models.dart`)",
        service="ActivityRepository",
        native="None",
        deps="DASH-01, TIME-01",
        status="NOT IMPLEMENTED",
        evidence="Dashboard links to Activity screen via button ('See reported app use'); no summary gauge embedded on dashboard.",
        missing="Daily screen time gauge component and daily aggregate computation on dashboard.",
        priority="P1",
        classification="Dashboard UI"
    )

    add_feature(
        fid="DASH-06",
        module="Module E: Parent Dashboard",
        name="Top App Usage Breakdown Snippet",
        expected="Snippet showing top 3 most used apps today with app icons and duration bars directly on the dashboard.",
        screens="DashboardPage",
        actions="View top apps, tap to view all apps.",
        ui_states="Top 3 apps list with horizontal duration bars.",
        controller="DashboardController",
        model="UsageLine",
        service="ActivityRepository",
        native="None",
        deps="DASH-01, APP-05",
        status="NOT IMPLEMENTED",
        evidence="None on dashboard (app usage exists only on dedicated `/devices/activity` route).",
        missing="Top 3 app ranking widget on dashboard.",
        priority="P1",
        classification="Dashboard UI"
    )

    add_feature(
        fid="DASH-07",
        module="Module E: Parent Dashboard",
        name="Recent Activity Feed Preview",
        expected="Timeline preview showing last 3 safety events (e.g., 'Arrived at School', 'Game time limit reached') with timestamps and navigation to full activity log.",
        screens="DashboardPage",
        actions="View recent events, tap 'View all activity'.",
        ui_states="Populated with recent events, or 'No recent activity'.",
        controller="DashboardController.data",
        model="AlertBoard (`apps/haven_app/lib/features/notifications/data/alerts_models.dart`)",
        service="AlertsRepository",
        native="None",
        deps="DASH-01, ALRT-02",
        status="PARTIAL",
        evidence="apps/haven_app/lib/features/dashboard/views/widgets/attention_card.dart:1-90\napps/haven_app/lib/features/dashboard/views/pages/dashboard_page.dart:94",
        missing="Card only shows high-severity alerts; normal activity events (geofence arrivals, app installations) not merged into feed.",
        priority="P1",
        classification="Dashboard UI"
    )

    add_feature(
        fid="DASH-08",
        module="Module E: Parent Dashboard",
        name="High-Priority Safety Alerts Banner",
        expected="Bold colored card alerting parent if any critical or warning safety alerts require attention, with tap to view all reports.",
        screens="DashboardPage",
        actions="Tap 'Open all reports' to view full alerts feed.",
        ui_states="Attention Card Visible (red/amber status), or hidden if zero alerts.",
        controller="DashboardController.goToNotifications",
        model="AlertBoard, AlertLine",
        service="AlertsRepository (`apps/haven_app/lib/features/notifications/data/alerts_repository.dart`)",
        native="None",
        deps="DASH-01, ALRT-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/dashboard/views/widgets/attention_card.dart:25-75\ntest/dashboard/dashboard_alerts_test.dart",
        missing="Push delivery integration.",
        priority="P0",
        classification="Alert UX"
    )

    add_feature(
        fid="DASH-09",
        module="Module E: Parent Dashboard",
        name="Quick Action Shortcuts Hub",
        expected="One-tap action buttons on dashboard: 'Commands / Instructions', 'Rule Versions', 'Remote Sessions' with direct navigation to management pages.",
        screens="DashboardPage",
        actions="Tap 'Instructions', tap 'Rule versions', tap 'Sessions'.",
        ui_states="Action buttons row/card.",
        controller="DashboardController.goToCommands, DashboardController.goToPolicies, DashboardController.goToSessions",
        model="None",
        service="None",
        native="None",
        deps="DASH-01",
        status="PARTIAL",
        evidence="apps/haven_app/lib/features/dashboard/views/widgets/device_records_card.dart:1-80\napps/haven_app/lib/features/dashboard/views/pages/dashboard_page.dart:98-102",
        missing="Buttons navigate to sub-pages; one-tap instant commands (e.g. pause device) lack client write grants.",
        priority="P1",
        classification="Dashboard Actions"
    )

    add_feature(
        fid="DASH-10",
        module="Module E: Parent Dashboard",
        name="Pull-to-Refresh Dashboard Sync",
        expected="Standard pull-to-refresh swipe gesture triggering parallel refresh of family bundle, devices, activity, safe zones, and alerts.",
        screens="DashboardPage",
        actions="Pull down on dashboard view.",
        ui_states="Refreshing spinner at top, contents updating.",
        controller="DashboardController.refresh (`dashboard_controller.dart:45`)",
        model="Result<DashboardData>",
        service="DashboardRepository.refresh",
        native="None",
        deps="DASH-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/dashboard/views/pages/dashboard_page.dart:24\napps/haven_app/lib/features/dashboard/controllers/dashboard_controller.dart:45-55\ntest/dashboard/dashboard_controller_test.dart",
        missing="None.",
        priority="P0",
        classification="Core UX"
    )

    add_feature(
        fid="DASH-11",
        module="Module E: Parent Dashboard",
        name="Dashboard Loading State",
        expected="Structured loading state rendered via `StateView` while initial data bundle resolves.",
        screens="DashboardPage",
        actions="Observe loading spinner on initial open.",
        ui_states="Centred CircularProgressIndicator.",
        controller="DashboardController.isLoading",
        model="RxBool",
        service="StateView component (`apps/haven_app/lib/shared/components/state_view.dart`)",
        native="None",
        deps="DASH-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/shared/components/state_view.dart:25-45\napps/haven_app/lib/features/dashboard/views/pages/dashboard_page.dart:27-33",
        missing="Shimmer skeleton layout (currently clean standard spinner).",
        priority="P2",
        classification="Core UX"
    )

    add_feature(
        fid="DASH-12",
        module="Module E: Parent Dashboard",
        name="Dashboard Empty Family / Needs Setup State",
        expected="When authenticated user has no family record, dashboard shows an informative card ('Haven is not set up yet') and a 'Start setup' button routing to `/onboarding`.",
        screens="DashboardPage",
        actions="Tap 'Start setup' button.",
        ui_states="Empty Setup SectionCard.",
        controller="DashboardController.goToSetup",
        model="None",
        service="None",
        native="None",
        deps="DASH-01, ONBD-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/dashboard/views/pages/dashboard_page.dart:161-180\ntest/dashboard/dashboard_page_test.dart",
        missing="None.",
        priority="P0",
        classification="Empty State"
    )

    add_feature(
        fid="DASH-13",
        module="Module E: Parent Dashboard",
        name="Stalled Backend Connection Banner",
        expected="Persistent amber/red banner at top of scaffold when build is unconfigured or staging backend is unreachable, stating exact missing `--dart-define` keys.",
        screens="All pages via HavenScaffold",
        actions="Tap banner to view missing build values.",
        ui_states="Banner visible with warning text and missing defines list.",
        controller="HavenConfig.status",
        model="BackendStatus, BackendReadiness",
        service="BackendBanner component (`apps/haven_app/lib/shared/components/backend_banner.dart`)",
        native="None",
        deps="AUTH-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/shared/components/backend_banner.dart:1-60\napps/haven_app/lib/shared/components/haven_scaffold.dart:30-40\ntest/shell/backend_banner_test.dart",
        missing="None.",
        priority="P0",
        classification="Diagnostic UX"
    )

    # MODULE F: LOCATION AND SAFE ZONES (14 features)
    add_feature(
        fid="LOC-01",
        module="Module F: Location and Safe Zones",
        name="Current Device Coordinate Display",
        expected="Displays device's latest reported location: latitude and longitude (with privacy show/hide toggle), accuracy in metres without fabricated precision, provider, and timestamp.",
        screens="LocationPage (Route: '/devices/location')",
        actions="Tap 'Show exact coordinates' / 'Hide exact coordinates', pull to refresh.",
        ui_states="Coordinates Hidden, Coordinates Revealed, Accuracy Meter, Age Formatter.",
        controller="LocationController (`apps/haven_app/lib/features/location/controllers/location_controller.dart`)",
        model="FixBoard, LocationEvent (`packages/haven_models/lib/src/location_models.dart`)",
        service="LocationRepository (`apps/haven_app/lib/features/location/data/location_repository.dart`)",
        native="None",
        deps="AUTH-01, PAIR-09",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/location/views/widgets/fix_card.dart:1-110\napps/haven_app/lib/features/location/views/pages/location_page.dart:46-66\ntest/location/location_page_test.dart",
        missing="None for coordinate display; verified with offline mock fakes.",
        priority="P0",
        classification="Location Core"
    )

    add_feature(
        fid="LOC-02",
        module="Module F: Location and Safe Zones",
        name="Interactive Map UI",
        expected="Interactive map (OpenStreetMap via FlutterMap or Google Maps) showing child's current pin, geofence circular overlays, zoom/pan controls, and satellite/street toggle.",
        screens="LocationMapPage / SafeZonesMapPage",
        actions="Pan map, zoom in/out, tap child pin to inspect accuracy circle, tap safe zone overlay.",
        ui_states="Map Loading, Map Rendered, Pin Marker Selected, Geofence Overlays.",
        controller="LocationController, ZonesController",
        model="LatLng, LocationEvent, SafeZone",
        service="MapTileService",
        native="None",
        deps="LOC-01, LOC-07",
        status="NOT IMPLEMENTED",
        evidence="safe_zones_page.dart:76-80 explicitly notes: 'This build has no map to tap a point on'.",
        missing="Interactive map integration (`flutter_map` or `google_maps_flutter`), map tiles configuration, pin rendering, touch gesture handlers.",
        priority="P0",
        classification="Map UI"
    )

    add_feature(
        fid="LOC-03",
        module="Module F: Location and Safe Zones",
        name="Location Metadata Details Inspector",
        expected="Detailed inspector for location fixes: reporting provider (GPS, Network, Passive), altitude, horizontal accuracy in metres, speed, and mock location provider detection flag.",
        screens="LocationPage",
        actions="Expand location fix card to view sensor metadata.",
        ui_states="Metadata details table.",
        controller="LocationController",
        model="LocationEvent (`packages/haven_models/lib/src/location_models.dart:1-60`)",
        service="LocationRepository",
        native="None",
        deps="LOC-01",
        status="COMPLETE",
        evidence="packages/haven_models/lib/src/location_models.dart:1-60\nandroid_native/child_services/location/LocationStateReader.kt:67-76\ntest/location/location_models_test.dart",
        missing="None. Fully typed and tested.",
        priority="P1",
        classification="Location Core"
    )

    add_feature(
        fid="LOC-04",
        module="Module F: Location and Safe Zones",
        name="Relative Last Updated Timestamp & Stale Indicator",
        expected="Displays human-readable relative age of fix ('Updated 2m ago'). Flags visual warning if fix is older than 30 minutes ('Fix may be stale - device was last active at 3:15 PM').",
        screens="LocationPage, DashboardPage",
        actions="Observe fix age label.",
        ui_states="Fresh (< 10m, neutral), Muted (10-30m), Stale Warning (> 30m, amber).",
        controller="LocationController",
        model="DateTime reportedAt",
        service="HavenTime (`apps/haven_app/lib/core/utils/haven_time.dart`)",
        native="None",
        deps="LOC-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/location/views/widgets/fix_card.dart:55-70\ntest/location/location_card_test.dart",
        missing="None.",
        priority="P0",
        classification="Location UX"
    )

    add_feature(
        fid="LOC-05",
        module="Module F: Location and Safe Zones",
        name="Historical Route Trail & Breadcrumbs",
        expected="Polyline trail on map and list of chronological coordinate breadcrumbs showing child's movements throughout selected date. Allows date selection.",
        screens="LocationHistoryPage (New Route: '/devices/location/history')",
        actions="Select date, scrub timeline slider, view movement points along route.",
        ui_states="Polyline trail on map, Breadcrumb point cards, Empty ('No location reported for this day').",
        controller="LocationHistoryController",
        model="List<LocationEvent>",
        service="LocationRepository.loadHistory",
        native="None",
        deps="LOC-01, LOC-02",
        status="UI ONLY",
        evidence="apps/haven_app/lib/features/location/views/widgets/fix_card.dart:35-50 (lists history rows; no polyline trail on map).",
        missing="Map polyline renderer, day picker, path interpolation.",
        priority="P1",
        classification="Location History"
    )

    add_feature(
        fid="LOC-06",
        module="Module F: Location and Safe Zones",
        name="Location Event Timeline & Dwell Time",
        expected="Groups raw location fixes into semantic clusters: 'Stayed at Home for 3h 12m', 'In transit for 18m', 'Arrived at School at 8:45 AM'.",
        screens="LocationTimelinePage",
        actions="View grouped dwell time cards.",
        ui_states="Timeline cluster items.",
        controller="LocationController",
        model="LocationClusterModel(placeName, arrivalTime, departureTime, duration)",
        service="LocationRepository",
        native="None",
        deps="LOC-05",
        status="NOT IMPLEMENTED",
        evidence="None in frontend.",
        missing="Dwell time clustering algorithm and timeline card component.",
        priority="P2",
        classification="Location Intelligence"
    )

    add_feature(
        fid="LOC-07",
        module="Module F: Location and Safe Zones",
        name="Safe Zones (Geofences) Directory Listing",
        expected="List of all safe zones configured for the family (Home, School, Park). Displays name, center coordinates, radius in metres, in-use switch, and edit button.",
        screens="SafeZonesPage (Route: '/safe-zones')",
        actions="View safe zones list, toggle zone in-use, tap edit to open editor, pull to refresh.",
        ui_states="Loading, Populated List, Empty Zones ('No safe places configured yet').",
        controller="SafeZonesController (`apps/haven_app/lib/features/safe_zones/controllers/zones_controller.dart`)",
        model="ZoneBoard, SafeZone (`packages/haven_models/lib/src/location_models.dart`)",
        service="ZonesRepository (`apps/haven_app/lib/features/safe_zones/data/zones_repository.dart`)",
        native="None",
        deps="AUTH-01, ONBD-04",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/safe_zones/views/widgets/zones_card.dart:1-95\napps/haven_app/lib/features/safe_zones/views/pages/safe_zones_page.dart:40-54\ntest/safe_zones/safe_zones_page_test.dart",
        missing="None.",
        priority="P0",
        classification="Geofence Core"
    )

    add_feature(
        fid="LOC-08",
        module="Module F: Location and Safe Zones",
        name="Add New Safe Zone Flow (Interactive Pin Drop)",
        expected="Interactive flow to create a new safe zone: address search, tap point on map, specify radius (20m - 5000m), name the zone (max 60 chars), and save to database.",
        screens="SafeZoneAddPage (New UI)",
        actions="Search address, tap point on map, enter name, adjust radius slider, tap 'Create Place'.",
        ui_states="Address Search Active, Pin Dropped, Circle Overlay Rendered, Submitting, Success.",
        controller="ZoneEditorController",
        model="SafeZoneDraft",
        service="ZonesRepository.createZone",
        native="None",
        deps="LOC-02, LOC-07",
        status="PLACEHOLDER",
        evidence="safe_zones_page.dart:66-72 notes 'the database lets a parent change a place but not create one, so there is no add button here to press'.",
        missing="Add safe zone page, address search geocoding, map tap selector, and backend INSERT grant.",
        priority="P0",
        classification="Geofence Mutation"
    )

    add_feature(
        fid="LOC-09",
        module="Module F: Location and Safe Zones",
        name="Safe Zone Editor Form",
        expected="Form allowing parent to edit an existing safe zone: change name, update latitude/longitude, adjust radius in metres, toggle in-use active switch. Enforces rules via `SafeZoneRules`.",
        screens="SafeZoneEditorPage (Route: '/safe-zones/editor')",
        actions="Edit name, edit lat/long, edit radius, toggle in-use, tap 'Save the change'.",
        ui_states="Loading, Form Loaded, Validating Error, Saving Busy, Saved Success.",
        controller="SafeZoneEditorController (`apps/haven_app/lib/features/safe_zones/controllers/zone_editor_controller.dart`)",
        model="SafeZone (`packages/haven_models/lib/src/location_models.dart`)",
        service="ZonesRepository.saveZone, SafeZoneRules (`apps/haven_app/lib/features/safe_zones/data/safe_zone_rules.dart`)",
        native="None",
        deps="LOC-07",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/safe_zones/views/pages/safe_zone_editor_page.dart:37-101\napps/haven_app/lib/features/safe_zones/data/safe_zone_rules.dart:1-105\ntest/safe_zones/zone_editor_page_test.dart",
        missing="Verified offline with 10 test files; live database UPDATE policy unexecuted.",
        priority="P0",
        classification="Geofence Mutation"
    )

    add_feature(
        fid="LOC-10",
        module="Module F: Location and Safe Zones",
        name="Geofence Radius Selection Slider",
        expected="Interactive slider allowing parent to select geofence radius between 20m and 5000m with live visual circle preview on map and preset buttons (100m, 250m, 500m, 1km).",
        screens="SafeZoneEditorPage, SafeZoneAddPage",
        actions="Drag radius slider, observe updated circle preview.",
        ui_states="Slider value updated, radius badge in metres.",
        controller="SafeZoneEditorController.radiusM",
        model="double radiusM",
        service="SafeZoneRules.radiusMin, SafeZoneRules.radiusMax",
        native="None",
        deps="LOC-09",
        status="PARTIAL",
        evidence="apps/haven_app/lib/features/safe_zones/views/pages/safe_zone_editor_page.dart:81-89 (currently numeric text field instead of slider with live map).",
        missing="Slider widget, preset buttons, and live map radius circle overlay.",
        priority="P1",
        classification="Geofence UX"
    )

    add_feature(
        fid="LOC-11",
        module="Module F: Location and Safe Zones",
        name="Delete Safe Zone Confirmation Flow",
        expected="Destructive action in Safe Zone Editor. Prompts parent with modal sheet to confirm deletion; removes geofence from database upon approval; returns to Safe Zones list.",
        screens="SafeZoneEditorPage",
        actions="Tap 'Remove this place', confirm in modal sheet.",
        ui_states="Confirmation Sheet Active, Deleting Busy, Deleted Redirection.",
        controller="SafeZoneEditorController.delete",
        model="Result<void>",
        service="ZonesRepository.deleteZone",
        native="None",
        deps="LOC-09",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/safe_zones/views/pages/safe_zone_editor_page.dart:125-155\napps/haven_app/lib/features/safe_zones/controllers/zone_editor_controller.dart:85-105\ntest/safe_zones/zone_editor_removal_page_test.dart",
        missing="Verified offline; live database DELETE policy unexecuted.",
        priority="P0",
        classification="Geofence Mutation"
    )

    add_feature(
        fid="LOC-12",
        module="Module F: Location and Safe Zones",
        name="Geofence Transition Events Card",
        expected="Displays recent safe zone entry and exit events: 'Leo entered School at 8:45 AM', 'Leo left School at 3:15 PM' with timestamp and duration spent.",
        screens="SafeZonesPage, DashboardPage",
        actions="View transition history.",
        ui_states="Entry/Exit event rows, Empty notice.",
        controller="SafeZonesController",
        model="SafeZoneStateRecord(zoneId, status, enteredAt, exitedAt)",
        service="ZonesRepository",
        native="None",
        deps="LOC-07",
        status="PLACEHOLDER",
        evidence="location_repository.dart:65-72 notes `safe_zone_states` is deny-all RLS.",
        missing="Table `safe_zone_states` is deny-all (RLS on, 0 policies); refused at seam.",
        priority="P1",
        classification="Geofence Telemetry"
    )

    add_feature(
        fid="LOC-13",
        module="Module F: Location and Safe Zones",
        name="Location Permission & GPS Disabled Notice",
        expected="Notice explaining why location is unavailable if child's GPS is off or location permission was denied, with troubleshooting steps.",
        screens="LocationPage",
        actions="Read troubleshooting guidance, tap 'Open device settings'.",
        ui_states="Permission Withheld Card ('Location withheld: GPS is off or permission denied').",
        controller="LocationController",
        model="FixBoard.withheldLine",
        service="LocationRepository",
        native="None",
        deps="LOC-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/location/views/widgets/fix_card.dart:80-105\nandroid_native/child_services/location/LocationStateReader.kt:42-44\ntest/location/location_page_test.dart",
        missing="None.",
        priority="P0",
        classification="Location UX"
    )

    add_feature(
        fid="LOC-14",
        module="Module F: Location and Safe Zones",
        name="Location Loading & Empty Fix States",
        expected="Clean empty state when device is newly paired and has never reported a location fix yet, clarifying that location updates only while child app is running.",
        screens="LocationPage",
        actions="View empty explanation.",
        ui_states="Empty fix card ('No location reported for this device yet').",
        controller="LocationController.board",
        model="FixBoard",
        service="None",
        native="None",
        deps="LOC-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/location/views/widgets/fix_card.dart:25-30",
        missing="None.",
        priority="P0",
        classification="Location UX"
    )

print("Modules D, E, F registered.")
