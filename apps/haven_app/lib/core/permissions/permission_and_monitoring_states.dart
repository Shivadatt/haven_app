/// The permission and monitoring answers, exactly as the phone gave them.
///
/// Every field here is a copy of one OS reply, and the shape keeps the three kinds
/// of answer apart: the phone said yes, the phone said no, or the phone had no
/// answer to give. A view may relabel them but may not merge them.
library;

/// What the OS grants this installed build, permission by permission.
final class PermissionStates {
  const PermissionStates({
    required this.granted,
    required this.undeclared,
    required this.declaredPermissions,
    required this.batteryExemptionDeclared,
    required this.bootReceiverDeclared,
  });

  /// One entry per permission the native lane asked about: `true` when granted,
  /// `false` when refused, `null` when the question had no answer.
  final Map<String, bool?> granted;

  /// The permissions this build does not declare, so the OS could never grant them.
  final Set<String> undeclared;

  /// Everything the installed APK declares, including what the plugins added.
  final List<String> declaredPermissions;

  final bool batteryExemptionDeclared;
  final bool bootReceiverDeclared;

  /// The four-way answer a screen should show for [key].
  PermissionAnswer answerFor(String key) {
    final bool? answer = granted[key];
    if (answer != null) {
      return answer ? PermissionAnswer.allowed : PermissionAnswer.notAllowed;
    }
    return undeclared.contains(key)
        ? PermissionAnswer.notDeclaredInThisBuild
        : PermissionAnswer.noSuchQuestion;
  }

  /// The keys the phone was able to consider at all on this Android version.
  List<String> get askableKeys => granted.keys
      .where((String key) => !undeclared.contains(key))
      .toList(growable: false);
}

/// The states [PermissionStates.answerFor] can land in.
enum PermissionAnswer {
  allowed('Allowed'),
  notAllowed('Not allowed'),
  notDeclaredInThisBuild('Not asked for in this build'),
  noSuchQuestion('This Android version cannot be asked');

  const PermissionAnswer(this.label);

  final String label;
}

/// Whether this phone would let monitoring work run, and how loudly it would show.
final class MonitoringStates {
  const MonitoringStates({
    required this.usageAccess,
    required this.usageAccessMode,
    required this.batteryOptimizationIgnored,
    required this.notificationImportance,
    required this.exactAlarmsAllowed,
    required this.serviceCount,
    required this.foregroundTypedServiceCount,
    required this.silentRingtone,
  });

  /// True only when the app-ops service said "allowed" — usage access is given in
  /// Settings, never through a dialog this app could show.
  final bool usageAccess;

  /// The app-ops mode itself: `allowed`, `ignored`, `system-default`, `refused`.
  final String usageAccessMode;

  final bool? batteryOptimizationIgnored;
  final String? notificationImportance;
  final bool? exactAlarmsAllowed;

  /// How many services the installed build declares, and how many of them name a
  /// foreground type. Background work is only possible where the OS was told what
  /// kind of work it is, so this is the manifest's answer, not ours.
  final int? serviceCount;
  final int? foregroundTypedServiceCount;

  final bool? silentRingtone;

  /// False only when the phone said the app-ops service would not answer at all.
  bool get usageAccessKnown => usageAccessMode != 'refused';

  /// What the app-ops service answered, in one line — the mode travels with the
  /// yes-or-no because "not allowed" has several different reasons behind it.
  String get usageLine => usageAccess
      ? 'Usage access: allowed by the phone.'
      : 'Usage access: not allowed (the phone answers: $usageAccessMode).';

  /// Whether a background service could announce itself, as the manifest says.
  String? get backgroundLine {
    final int? services = serviceCount;
    if (services == null) return null;
    final int typed = foregroundTypedServiceCount ?? 0;
    return '$services services are declared in this build, $typed of them with a '
        'foreground type the phone recognises.';
  }
}
