import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

/// One `device_policies` row: a version number and what a device said about it.
///
/// The rule set inside the row is a JSON object and nothing captured says what
/// its keys mean, so this line describes the version and the answer, not the
/// rules. Saying more than that would be a policy Haven invented.
final class PolicyLine {
  const PolicyLine(this.policy, {this.deviceName});

  final DevicePolicy policy;

  /// The device row this version was written for, when one could be read.
  final String? deviceName;

  String get whose => deviceName ?? 'a device this build cannot name';

  String get which => 'Version ${policy.version}';

  String get written => 'written ${_stamp(policy.createdAt)}';

  /// `acknowledged_at` is set by the device, so an answer is reported only when
  /// that column or a status the device could only reach is present.
  String? get answered {
    final DateTime? acked = policy.acknowledgedAt;
    return acked == null ? null : 'answered ${_stamp(acked)}';
  }

  /// Whether the device said it applied this version. A row written by a parent
  /// is never evidence that a phone changed.
  String get outcome {
    final String word = switch (policy.statusEnum) {
      PolicyEnforcementStatus.pending => 'No answer from the device yet',
      PolicyEnforcementStatus.enforced =>
        'The device said it applied this version',
      PolicyEnforcementStatus.failed =>
        'The device said it could not apply this version',
      PolicyEnforcementStatus.unsupported =>
        'The device said it cannot apply rules like this',
      null => 'A state this build does not recognise',
    };
    if (policy.statusEnum == null) return '$word (${policy.enforcementStatus})';
    return word;
  }

  /// `last_error` is capped at 500 characters and is the device's own words.
  String? get trouble => policy.lastError;

  String get statusLabel => policy.statusEnum?.label ?? 'Unrecognised';

  static String _stamp(DateTime when) => when.toUtc().toIso8601String();
}

/// The versions this family may read, and the three things they do not answer.
final class PolicyBoard {
  const PolicyBoard({
    required this.familyId,
    required this.lines,
    required this.writeGap,
    required this.ruleShapeGap,
    this.deviceGap,
    this.deviceId,
  });

  final String familyId;

  /// The device the read was narrowed to, or null for the whole family
  /// (`docs/implementation/00-app-contract.md:161`).
  final String? deviceId;
  final List<PolicyLine> lines;

  /// Writing a new version and telling a device to adopt one are the same
  /// missing grant: no client role may write this table, and the RPC that would
  /// pass the version on holds no EXECUTE.
  final BlockedFailure writeGap;

  /// What the rules inside a version are. `policy` is only proven to be a JSON
  /// object, so the shape of a rule set is a specification this build does not
  /// have.
  final BlockedFailure ruleShapeGap;

  /// The refusal that would otherwise name each version's device.
  final BlockedFailure? deviceGap;

  bool get hasLines => lines.isNotEmpty;

  /// A page size, not a history. Superseded versions are said to be pruned after
  /// 90 days in `docs/stage1/03-data-model.md:92`; that is a plan, not a captured
  /// rule, so no screen claims to show every version that ever existed.
  static const int window = 10;

  String get counted =>
      '${lines.length} ${lines.length == 1 ? 'version' : 'versions'} read — '
      'the newest $window rows the backend would give, for '
      '${deviceId == null ? 'this family' : 'one device'}.';

  /// The greatest version number among the rows read. Deliberately not called
  /// "the current policy": effective-policy resolution is listed as unproven in
  /// `docs/stage1/03-data-model.md:36`.
  int? get highestVersionRead {
    if (lines.isEmpty) return null;
    return lines
        .map((PolicyLine line) => line.policy.version)
        .reduce((int a, int b) => a > b ? a : b);
  }

  int get enforcedCount =>
      lines.where((PolicyLine line) => line.policy.isEnforcedOnDevice).length;

  String get enforcedLine =>
      '$enforcedCount of ${lines.length} carry an answer from a device saying '
      'it applied them.';

  /// The one sentence that keeps a version number from being read as live rules.
  String get newestLine =>
      'Version $highestVersionRead is the highest number among them. A number '
      'here is not the set of rules a device is following.';
}
