import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haven_core/haven_core.dart';

import 'package:haven_child/core/permissions/child_permission.dart';
import 'package:haven_child/core/permissions/permission_status_source.dart';
import 'package:haven_child/core/permissions/unconfigured_permission_status_source.dart';

/// Brief §7: "permission status mapping (all four categories resolve to
/// blocked/Unavailable, never granted)".
void main() {
  const source = UnconfiguredPermissionStatusSource();

  group('the four declared capabilities', () {
    test('there are exactly four, each with unique wire, label, why and icon', () {
      expect(ChildPermission.values.length, 4);
      final wires = ChildPermission.values.map((p) => p.wire).toSet();
      expect(wires.length, 4);
      for (final permission in ChildPermission.values) {
        expect(permission.wire, isNotEmpty);
        expect(permission.label, isNotEmpty);
        // The WHY copy is what a child reads before anything is ever asked.
        expect(permission.why.length, greaterThan(40));
        expect(permission.icon, isA<IconData>());
      }
      expect(
        wires,
        {'usage_access', 'location', 'notifications', 'background_activity'},
      );
    });

    test('every category resolves to blocked — the Stage-1 promise', () async {
      for (final permission in ChildPermission.values) {
        final status = await source.statusOf(permission);
        expect(
          status.isErr,
          isTrue,
          reason: '${permission.wire} must not answer Ok without a reader',
        );
        expect(isBlocked(status), isTrue);
        final failure = status.failureOrNull!;
        expect(failure, isA<BlockedFailure>());
        expect(
          failure.detail!,
          startsWith('BLOCKED — SPECIFICATION REQUIRED'),
        );
      }
    });

    test('the refusal names the missing piece and the permission precisely', () async {
      for (final permission in ChildPermission.values) {
        final failure = (await source.statusOf(permission)).failureOrNull!;
        expect(
          (failure as BlockedFailure).missing,
          contains(permission.wire),
        );
        expect(failure.missing, contains('Kotlin lane'));
        // The child-readable requirement line mentions the capability.
        expect(
          failure.message,
          contains(permission.label.toLowerCase()),
        );
      }
    });

    test('no answer can carry granted: the status type has no Ok path here', () async {
      for (final permission in ChildPermission.values) {
        final status = await source.statusOf(permission);
        // Rendered "Unavailable" by the card; a null value is what makes the
        // UI physically unable to print Granted.
        expect(status.valueOrNull, isNull);
      }
    });
  });

  group('the shared render vocabulary', () {
    test('the card label and the settings note are single-sourced strings', () {
      expect(
        UnconfiguredPermissionStatusSource.cardStatusLabel,
        'Unavailable — not yet implemented on this device build',
      );
      expect(
        UnconfiguredPermissionStatusSource.settingsActionNote,
        contains('not part of this build'),
      );
    });

    test('PermissionStatus itself only exists behind an Ok read', () {
      // The type is constructible for a FUTURE real reader; the contract in
      // tests is that no Stage-1 source can produce one (proved above).
      final status = PermissionStatus(
        permission: ChildPermission.location,
        granted: false,
      );
      expect(status.granted, isFalse);
      expect(status.permission, ChildPermission.location);
    });
  });

  test('the interface stays Result-typed — a blocked Err is not an exception', () async {
    // isBlocked is the view-side check the contract mandates.
    final Result<PermissionStatus> answer = await source.statusOf(
      ChildPermission.usageAccess,
    );
    expect(isBlocked(answer), isTrue);
    expect(answer, isA<Err<PermissionStatus>>());
  });
}
