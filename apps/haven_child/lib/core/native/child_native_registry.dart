import 'child_native_contract.dart';

/// The agreement table: every name both sides must share, keyed one at a time.
///
/// Tests assert on this per key — `byId['section.deviceAdmin']` against the
/// Kotlin constant it names — so a drift reports the single name that moved
/// rather than one whole-blob string comparison that hides which one broke.
abstract final class ChildNativeContract {
  /// The Dart copy of each Kotlin constant, with the file and declaration it
  /// mirrors. Order is the reading order of the Kotlin surface: channel,
  /// method, envelope, errors, sections, permission keys.
  static List<ChildNativeContractEntry> get entries =>
      <ChildNativeContractEntry>[
        const ChildNativeContractEntry(
          id: 'channel',
          dartValue: ChildNativeChannel.name,
          kotlinFile: ChildNativeKotlinSource.bridgeContract,
          kotlinConstant: 'CHANNEL',
        ),
        const ChildNativeContractEntry(
          id: 'method',
          dartValue: ChildNativeMethod.readAll,
          kotlinFile: ChildNativeKotlinSource.bridgeContract,
          kotlinConstant: 'METHOD_READ_ALL',
        ),
        for (final String key in ChildNativeEnvelopeKey.all)
          ChildNativeContractEntry(
            id: 'envelope.$key',
            dartValue: key,
            kotlinFile: ChildNativeKotlinSource.bridgeContract,
            kotlinConstant: ChildNativeEnvelopeKey.kotlinConstants[key]!,
          ),
        for (final String code in ChildNativeErrorCode.all)
          ChildNativeContractEntry(
            id: 'error.$code',
            dartValue: code,
            kotlinFile: ChildNativeKotlinSource.bridgeContract,
            kotlinConstant: ChildNativeErrorCode.kotlinConstants[code]!,
          ),
        for (final ChildNativeSection section in ChildNativeSection.values)
          ChildNativeContractEntry(
            id: 'section.${section.wire}',
            dartValue: section.wire,
            kotlinFile: ChildNativeKotlinSource.sections,
            kotlinConstant: section.kotlinConstant,
          ),
        for (final ChildNativePermissionKey key in ChildNativePermissionKey.values)
          ChildNativeContractEntry(
            id: 'permission.${key.wire}',
            dartValue: key.wire,
            kotlinFile: ChildNativeKotlinSource.osAnswers,
            kotlinConstant: 'TrackedPermission.${key.kotlinEntry}',
          ),
      ];

  /// `id` → the value this side would put on the wire.
  static Map<String, String> get byId => <String, String>{
    for (final ChildNativeContractEntry e in entries) e.id: e.dartValue,
  };

  /// `BridgeContract.KEY_API_LEVEL`-style lookup, for reading the parsed Kotlin.
  static ChildNativeContractEntry byKotlinConstant(String declarationName) {
    for (final ChildNativeContractEntry e in entries) {
      if (e.kotlinConstant == declarationName) return e;
    }
    // A name that is not in the table is a bug in this file, not a runtime
    // condition: the agreement test would have caught the drift first.
    throw ArgumentError.value(
      declarationName,
      'declarationName',
      'no Dart mirror for this Kotlin constant',
    );
  }

  /// How many names the surface promises; a shortened table is a breaking drift.
  static const int expectedEntryCount = 19;

  /// What the child says when asked to use this surface today.
  ///
  /// Kept here rather than in a view so the wording cannot be softened into
  /// something that sounds like a live read.
  static const String laneAvailabilityNote =
      'This child build has no native lane: android_native is compiled by the '
      'parent app only, so every name in this file is a contract with nothing '
      'behind it yet. No device state is read, and none is guessed.';
}
