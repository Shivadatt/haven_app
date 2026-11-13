import 'dart:async';

import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import '../data/child_registration_service.dart';
import '../domain/registration_codec.dart';
import '../domain/registration_status.dart';

/// Binds a `ChildRegistrationService` to observable state.
///
/// No route and no page is added by Stage 2: this is the contract half of the
/// workstream, so the controller exists for tests, for the label-only widget
/// below, and for whichever screen Stage 3 introduces. `service.laneLabel`
/// (`DEMO` / `BLOCKED`) has to be rendered next to any status this controller
/// exposes — a DEMO registration and a real one must never look identical.
final class RegistrationController extends GetxController {
  RegistrationController({required this.service});

  final ChildRegistrationService service;

  final Rxn<RegistrationStatus> status = Rxn<RegistrationStatus>();
  final RxBool isBusy = false.obs;
  final RxnString message = RxnString();

  StreamSubscription<RegistrationStatus>? _subscription;

  /// The in-flight guard the parent's older simulation controller does not
  /// have (see `STAGE_2_READINESS_AND_OWNER_DECISIONS.md` §3 refinement):
  /// `isBusy` alone is set after the first await, so a programmatic caller
  /// could double-submit. This flag is set before any await.
  bool _inFlight = false;

  String get laneLabel => service.laneLabel;

  RegistrationStatus get currentStatus => status.value ?? service.current;

  List<String> get auditEvents => service.audit
      .map((row) => row.kind.wire)
      .toList(growable: false);

  @override
  void onInit() {
    super.onInit();
    status.value = service.current;
    _subscription = service.state.listen(_onStatusEvent);
    unawaited(restore());
  }

  /// Loads whatever the lane persisted. The BLOCKED lane answers with the
  /// empty snapshot; a typed storage failure is reported, never swallowed.
  Future<void> restore() async {
    final Result<RegistrationSnapshot> loaded = await service.restore();
    final RegistrationSnapshot? snapshot = loaded.valueOrNull;
    if (snapshot != null) {
      _onStatusEvent(snapshot.status);
      return;
    }
    _setMessage(loaded.failureOrNull);
  }

  Future<Result<RegistrationStatus>> submitPairingCode(String code) =>
      _run(() => service.submitPairingCode(code));

  Future<Result<RegistrationStatus>> unpair() => _run(service.unpair);

  Future<Result<RegistrationStatus>> _run(
    Future<Result<RegistrationStatus>> Function() operation,
  ) async {
    if (_inFlight) {
      return const Err<RegistrationStatus>(
        ValidationFailure(
          'Haven is still working on the last step — wait for it to finish.',
          field: 'registration',
          detail: 'in_flight_guard',
        ),
      );
    }
    _inFlight = true;
    isBusy.value = true;
    message.value = null;
    try {
      final Result<RegistrationStatus> result = await operation();
      if (isClosed) return result;
      if (result case Err<RegistrationStatus>(:final HavenFailure failure)) {
        _setMessage(failure);
      } else {
        status.value = result.valueOrNull;
      }
      return result;
    } finally {
      _inFlight = false;
      if (!isClosed) isBusy.value = false;
    }
  }

  void _onStatusEvent(RegistrationStatus next) {
    if (isClosed) return;
    status.value = next;
  }

  void _setMessage(HavenFailure? failure) {
    if (isClosed || failure == null) return;
    message.value = failure.message;
  }

  @override
  void onClose() {
    // The stream belongs to the service; this controller only ever drops its
    // own subscription.
    _subscription?.cancel();
    _subscription = null;
    super.onClose();
  }
}
