/// What the phone confirms about its admin standing and its capture hardware.
///
/// These two areas share a file because they share the rule the rest of the lane is
/// built on: an installed app that is not the device owner is routinely told
/// *nothing*, and that silence is the finding — not a "no" to be displayed as one.
library;

/// What `DevicePolicyManager` confirms about this app's standing on the phone.
///
/// [restrictionsReadable] is the field every claim about an applied rule has to
/// pass through. For an installed app that is not a device or profile owner the OS
/// refuses the reading, so it is `null` — and no sentence about a restriction being
/// in force may be built on a `null`.
final class DeviceAdminStates {
  const DeviceAdminStates({
    required this.serviceAvailable,
    required this.receiverDeclared,
    required this.adminActive,
    required this.deviceOwner,
    required this.profileOwner,
    required this.activeAdminCount,
    required this.restrictionsInForce,
    required this.screenLockTimeout,
    required this.storageEncryptionState,
    required this.restrictionsReadable,
  });

  final bool serviceAvailable;

  /// True when this build declares the admin component the question is asked about.
  final bool receiverDeclared;
  final bool adminActive;
  final bool? deviceOwner;
  final bool? profileOwner;
  final int? activeAdminCount;

  /// The restriction keys the OS reports as in force, in the system's own names —
  /// `null` when the phone would not hand the reading to this app at all.
  ///
  /// A normal installed app is never handed this, so `null` here is the common case
  /// and the only honest basis for a screen saying it cannot confirm a rule.
  final List<String>? restrictionsInForce;

  /// `null` both when no timeout rule exists and when the phone would not say; the
  /// phone's own "no limit set" answer is not reported as a 292-million-year timeout.
  final Duration? screenLockTimeout;

  final String? storageEncryptionState;
  final bool? restrictionsReadable;

  /// The only answer that can support a sentence about a rule being in force.
  bool get canConfirmARestriction => restrictionsReadable == true;

  /// Whether the phone will confirm rules, and what it confirmed.
  ///
  /// The refusal is the normal case and is shown as such: an installed app that is
  /// not a device or profile owner is not handed this reading by the OS, so Haven
  /// says the phone would not tell it rather than implying nothing is blocked.
  String get restrictionLine {
    final List<String>? inForce = restrictionsInForce;
    if (inForce == null) {
      return 'This phone will not tell an app that is not its device owner which '
          'rules are in force.';
    }
    if (inForce.isEmpty) {
      return 'The phone reports no rules in force for this app.';
    }
    return 'The phone reports ${inForce.length} rule(s) in force: '
        '${inForce.join(', ')}.';
  }

  /// Haven's standing on this phone, as the phone states it.
  String get standingLine => adminActive
      ? 'The phone says this app is an active device admin.'
      : 'The phone says this app is not an active device admin.';
}

/// What the phone says about its microphone and camera before either is used.
final class CommunicationStates {
  const CommunicationStates({
    required this.microphoneAllowed,
    required this.cameraAllowed,
    required this.audioServiceAvailable,
    required this.microphoneMuted,
    required this.audioMode,
    required this.speakerphoneOn,
    required this.inputDeviceCount,
    required this.cameraCount,
  });

  final bool? microphoneAllowed;
  final bool? cameraAllowed;
  final bool? audioServiceAvailable;
  final bool? microphoneMuted;

  /// `normal`, `ringing`, `in-call`, `in-communication`, `refused`.
  final String? audioMode;
  final bool? speakerphoneOn;

  /// Hardware counts, read from the OS's lists. Counting a camera does not open it.
  final int? inputDeviceCount;
  final int? cameraCount;

  /// The hardware and the grants, one line, with the counting kept separate from
  /// the using: nothing in this lane can start capture.
  String get mediaLine {
    final int? mics = inputDeviceCount;
    final int? cameras = cameraCount;
    final String hardware = mics == null || cameras == null
        ? 'the phone would not say what audio inputs or cameras it has'
        : '$mics audio input(s) and $cameras camera(s) are present';
    return 'Microphone ${_word(microphoneAllowed)}, camera ${_word(cameraAllowed)}; '
        '$hardware.';
  }

  static String _word(bool? answer) => switch (answer) {
    true => 'is allowed',
    false => 'is not allowed',
    null => 'cannot be asked in this build',
  };
}
