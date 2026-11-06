import 'package:flutter_test/flutter_test.dart';

import 'package:haven_child/core/permissions/child_permission.dart';
import 'package:haven_child/features/permissions/controllers/permissions_controller.dart';

import '../../support/fakes.dart';

/// Controller transitions (contract §Test conventions): the blocked answer
/// stays a blocked answer all the way into the card list — the UI never
/// sees a reshaped "denied".
void main() {
  test('one load answers all four categories exactly once', () async {
    final source = FakePermissionStatusSource();
    final subject = PermissionsController(source: source);
    await subject.load();

    expect(subject.isLoading.value, isFalse);
    expect(subject.cards.length, 4);
    expect(source.callCount, 4);
    expect(
      subject.cards.map((c) => c.permission).toList(),
      ChildPermission.values,
    );
  });

  test('blocked reads are carried verbatim, never converted to granted', () async {
    final subject = PermissionsController(source: FakePermissionStatusSource());
    await subject.load();
    for (final card in subject.cards) {
      expect(card.status.isErr, isTrue);
      expect(card.status.valueOrNull, isNull);
    }
    expect(subject.errorMessage.value, isNull);
  });

  test('granted data resolves through to the card state', () async {
    final source = FakePermissionStatusSource()
      ..grantedOverrides[ChildPermission.notifications] = true;
    final subject = PermissionsController(source: source);
    await subject.load();

    final notification = subject.cards.firstWhere(
      (c) => c.permission == ChildPermission.notifications,
    );
    expect(notification.status.valueOrNull!.granted, isTrue);
    final usage = subject.cards.firstWhere(
      (c) => c.permission == ChildPermission.usageAccess,
    );
    // Everything not really read stays blocked — a partial reader cannot
    // make the others look denied.
    expect(usage.status.valueOrNull, isNull);
  });

  test('a throwing source sets the error and ends the loading state', () async {
    final subject = PermissionsController(
      source: FakePermissionStatusSource(mode: PermissionFakeMode.throws),
    );
    await subject.load();
    expect(subject.isLoading.value, isFalse);
    expect(subject.errorMessage.value, contains('could not be loaded'));
    expect(subject.cards, isEmpty);
  });

  test('retry clears the previous error before re-asking', () async {
    final source = FakePermissionStatusSource();
    final subject = PermissionsController(source: source);
    await subject.load();
    source.mode = PermissionFakeMode.throws;
    await subject.load();
    source.mode = PermissionFakeMode.blocked;
    await subject.load();
    expect(subject.errorMessage.value, isNull);
    expect(subject.cards.length, 4);
  });
}
