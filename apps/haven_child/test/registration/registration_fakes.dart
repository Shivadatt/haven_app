import 'dart:async';

import 'package:haven_core/haven_core.dart';
import 'package:haven_child/features/registration/data/child_registration_service.dart';
import 'package:haven_child/features/registration/domain/registration_audit.dart';
import 'package:haven_child/features/registration/domain/registration_codec.dart';
import 'package:haven_child/features/registration/domain/registration_status.dart';

/// `flutter_test` runs on a fake async zone; draining microtasks and the
/// stream queue is what "the state has landed" means here.
Future<void> pumpMicrotasks() => Future<void>.delayed(Duration.zero);

/// A hand-written service whose answer is held open until the test releases
/// it — the only way to prove an in-flight guard is real.
///
/// Split out of `registration_controller_test.dart` under the 200-line source
/// rule; behaviour is unchanged.
final class HangingService implements ChildRegistrationService {
  HangingService({this.failing});

  final HavenFailure? failing;
  final Completer<void> _gate = Completer<void>();
  int calls = 0;

  void release() {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  RegistrationStatus get current => const Unregistered();

  @override
  String get laneLabel => 'FAKE';

  @override
  Stream<RegistrationStatus> get state =>
      const Stream<RegistrationStatus>.empty();

  @override
  List<RegistrationAuditRow> get audit => const <RegistrationAuditRow>[];

  @override
  Future<Result<RegistrationSnapshot>> restore() async =>
      Ok<RegistrationSnapshot>(RegistrationSnapshot(status: current));

  @override
  Future<Result<RegistrationStatus>> submitPairingCode(String code) async {
    calls++;
    final HavenFailure? failure = failing;
    if (failure != null) {
      // A scripted failure answers immediately; only the in-flight-guard case
      // has to be held open, and holding a failing answer open would hang.
      return Err<RegistrationStatus>(failure);
    }
    await _gate.future;
    return Ok<RegistrationStatus>(
      Registered(
        stableLocalId: 'child-hanging',
        registeredAt: DateTime.utc(2026, 11, 13),
      ),
    );
  }

  @override
  Future<Result<RegistrationStatus>> unpair() async => okVoid().map(
        (_) => Ok<RegistrationStatus>(const Unregistered()),
        (HavenFailure failure) => Err<RegistrationStatus>(failure),
      );
}

/// A lane whose persisted state cannot be read back — the restore path must
/// surface the typed failure, not pretend the device is new.
final class UnreadableService implements ChildRegistrationService {
  @override
  RegistrationStatus get current => const Unregistered();

  @override
  String get laneLabel => 'FAKE';

  @override
  Stream<RegistrationStatus> get state =>
      const Stream<RegistrationStatus>.empty();

  @override
  List<RegistrationAuditRow> get audit => const <RegistrationAuditRow>[];

  @override
  Future<Result<RegistrationSnapshot>> restore() async =>
      const Err<RegistrationSnapshot>(
        StorageFailure('The local data could not be read.'),
      );

  @override
  Future<Result<RegistrationStatus>> submitPairingCode(String code) async =>
      blocked<RegistrationStatus>('fake lane');

  @override
  Future<Result<RegistrationStatus>> unpair() async =>
      blocked<RegistrationStatus>('fake lane');
}
