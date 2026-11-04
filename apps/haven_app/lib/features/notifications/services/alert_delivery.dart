import 'package:haven_core/haven_core.dart';

import '../data/alerts_repository.dart';

/// The server half of push delivery: handing this device over so the backend can
/// reach it.
///
/// The device half already exists and works — `PushTransport` in `haven_api`
/// captures the token, asks the operating system for permission, and reports what
/// the OS answered. What is missing is somewhere for that token to go, so this
/// interface exists to refuse rather than to pretend a subscription was made.
abstract interface class AlertDelivery {
  /// Would register a push target for the signed-in account.
  Future<Result<void>> registerTarget(String target);

  /// Would withdraw it again.
  Future<Result<void>> clearTarget();

  /// Whether this device is registered with the backend for reports. Nothing can
  /// make this true in this build, and no screen may imply that a report will
  /// arrive on the phone.
  bool get isRegistered;
}

/// The only implementation the evidence allows.
///
/// A token that is captured and then has nowhere to be stored is not a delivery
/// path, and nothing here claims one: this returns the same refusal the reports
/// screen renders, so the sentence a parent reads and the sentence the code gives
/// are the same sentence.
final class UnregisteredAlertDelivery implements AlertDelivery {
  const UnregisteredAlertDelivery();

  @override
  Future<Result<void>> registerTarget(String target) =>
      _refuse('hand this device to the backend for push delivery');

  @override
  Future<Result<void>> clearTarget() =>
      _refuse('withdraw this device from push delivery');

  @override
  bool get isRegistered => false;

  static Future<Result<void>> _refuse(String what) async => blocked<void>(
    HavenAlertsRepository.deliveryMissing,
    requirement: 'Haven cannot $what in this build yet.',
  );
}
