import 'package:flutter/material.dart';

/// The four capabilities a later Phase 3 stage may grow on this device.
///
/// Naming them here does NOT request them: Stage 1 declares zero runtime
/// permissions and reads zero permission state. Each entry carries the
/// age-appropriate WHY copy the dashboard shows, so the child can read what
/// the permission will mean before any stage ever asks.
enum ChildPermission {
  usageAccess(
    wire: 'usage_access',
    label: 'Screen time access',
    why:
        'Lets Haven count how long each app was used, so you and your parent '
        'can see the same numbers. Nothing is counted until this is switched '
        'on in Android settings, on purpose, by an adult.',
    icon: Icons.hourglass_bottom,
  ),
  location(
    wire: 'location',
    label: 'Location',
    why:
        'Lets Haven show where the device is, only while the app is allowed '
        'to see it. Without it, no place is ever recorded.',
    icon: Icons.location_on_outlined,
  ),
  notifications(
    wire: 'notifications',
    label: 'Notifications',
    why:
        'Lets Haven show gentle reminders, like a heads-up before bedtime. '
        'Without it the app stays completely quiet.',
    icon: Icons.notifications_none,
  ),
  backgroundActivity(
    wire: 'background_activity',
    label: 'Runs in the background',
    why:
        'Lets Haven keep working when the screen is off or the app is closed. '
        'Until this exists, the app only knows what it saw while it was open.',
    icon: Icons.battery_charging_full,
  );

  const ChildPermission({
    required this.wire,
    required this.label,
    required this.why,
    required this.icon,
  });

  final String wire;
  final String label;
  final String why;
  final IconData icon;
}
