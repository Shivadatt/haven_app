import 'package:flutter_test/flutter_test.dart';
import 'package:haven_child/core/native/child_native_contract.dart';
import 'package:haven_child/core/native/child_native_registry.dart';

import 'kotlin_source_lane.dart';

/// D-4 option B, child side: the Kotlin constants are authoritative and this
/// test is the enforcement mechanism. Every entry in
/// [ChildNativeContract.entries] is compared, per item, against the string the
/// Kotlin file actually holds on disk — and in the other direction, every
/// constant Kotlin declares must appear in the Dart mirror, so a Kotlin-side
/// addition fails this test just as loudly as a rename.
///
/// Nothing here opens a channel; the child build has no native lane (see
/// `blockedChildNativeLane`). What is being agreed is the contract a future
/// child lane will implement.
void main() {
  final KotlinSourceLane lane = KotlinSourceLane.open();
  final Map<String, String> bridge = KotlinSourceLane.constValues(
    lane.read(ChildNativeKotlinSource.bridgeContract),
  );
  final Map<String, String> sections = KotlinSourceLane.constValues(
    lane.read(ChildNativeKotlinSource.sections),
  );
  final Map<String, String> permissions = KotlinSourceLane.trackedPermissionKeys(
    lane.read(ChildNativeKotlinSource.osAnswers),
  );

  String? kotlinValueFor(ChildNativeContractEntry entry) {
    if (entry.kotlinFile == ChildNativeKotlinSource.bridgeContract) {
      return bridge[entry.kotlinConstant];
    }
    if (entry.kotlinFile == ChildNativeKotlinSource.sections) {
      return sections[entry.kotlinConstant];
    }
    if (entry.kotlinFile == ChildNativeKotlinSource.osAnswers) {
      return permissions[entry.kotlinConstant.split('.').last];
    }
    return null;
  }

  test('the Kotlin files declare the constants the mirror claims to mirror', () {
    // A regex that matched nothing would silently vacate every per-entry check.
    expect(bridge, hasLength(9));
    expect(sections, hasLength(5));
    expect(permissions, hasLength(5));
  });

  test('the registry is complete and its ids unique', () {
    final List<ChildNativeContractEntry> entries = ChildNativeContract.entries;
    expect(entries, hasLength(ChildNativeContract.expectedEntryCount));
    expect(ChildNativeContract.expectedEntryCount, 19);
    expect(entries.map((ChildNativeContractEntry e) => e.id).toSet(), hasLength(19));
    expect(ChildNativeContract.byId.entries.every((MapEntry<String, String> e) =>
      e.value.isNotEmpty), isTrue);
  });

  group('per-item agreement with the Kotlin source on disk', () {
    for (final ChildNativeContractEntry entry in ChildNativeContract.entries) {
      test(entry.id, () {
        expect(
          kotlinValueFor(entry),
          entry.dartValue,
          reason: 'Dart mirrors $entry — a drift here breaks the future lane '
              'silently on both sides at once',
        );
      });
    }
  });

  test('no Kotlin constant exists without a Dart mirror', () {
    final Set<String> mirroredBridge = ChildNativeContract.entries
        .where((ChildNativeContractEntry e) =>
            e.kotlinFile == ChildNativeKotlinSource.bridgeContract)
        .map((ChildNativeContractEntry e) => e.kotlinConstant)
        .toSet();
    expect(
      bridge.keys.toSet(),
      mirroredBridge,
      reason: 'a new BridgeContract constant must be mirrored before it ships',
    );
    expect(
      sections.keys.toSet(),
      ChildNativeSection.values
          .map((ChildNativeSection s) => s.kotlinConstant)
          .toSet(),
    );
    expect(
      permissions.keys.toSet(),
      ChildNativePermissionKey.values
          .map((ChildNativePermissionKey k) => k.kotlinEntry)
          .toSet(),
    );
  });

  test('HavenBridge registers exactly the five readers the mirror names', () {
    final List<String> registered = KotlinSourceLane.registeredReaders(
      lane.read(ChildNativeKotlinSource.havenBridge),
    );
    expect(registered, ChildNativeSection.values.map((ChildNativeSection s) => s.readerClass).toList());
    for (final String reader in registered) {
      expect(
        ChildNativeSection.values
            .any((ChildNativeSection s) => s.readerClass == reader),
        isTrue,
        reason: '$reader is registered in Kotlin but has no Dart mirror',
      );
    }
  });

  test('every mirrored reader class resolves to a real Kotlin file', () {
    for (final ChildNativeSection section in ChildNativeSection.values) {
      final String path =
          ChildNativeKotlinSource.pathOfReader(section.readerClass);
      expect(
        () => lane.read(path),
        returnsNormally,
        reason: 'the mirror points at a file that is not on disk: $path',
      );
    }
    // The registration regex itself stays honest against the real file.
    expect(
      RegExp(ChildNativeKotlinSource.readerClassPattern)
          .hasMatch(lane.read(ChildNativeKotlinSource.havenBridge)),
      isTrue,
    );
  });

  test('the lane availability note names the block it declares', () {
    expect(ChildNativeContract.laneAvailabilityNote, contains('no native lane'));
    expect(ChildNativeContract.laneAvailabilityNote, contains('parent app only'));
  });
}
