import 'dart:async';

import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../../core/native/usage_envelope_models.dart';
import '../../child_usage/data/child_usage_repository.dart';
import '../data/child_policy_record.dart';
import '../data/child_policy_repository.dart';
import '../data/policy_usage_adapter.dart';

/// Lifecycle of the active child policy.
enum ChildPolicyStatus { initial, loading, ready, failure }

/// Owns the active policy and performs fresh usage evaluation.
final class ChildPolicyController extends GetxController {
  ChildPolicyController({
    required this.policyRepository,
    required this.usageRepository,
    this.clock = systemClock,
  });
  final ChildPolicyRepository policyRepository;
  final ChildUsageRepository usageRepository;
  final Clock clock;
  final Rx<ChildPolicyStatus> status = ChildPolicyStatus.initial.obs;
  final Rxn<ChildPolicyRecord> activePolicy = Rxn<ChildPolicyRecord>();
  final Rxn<HavenFailure> policyFailure = Rxn<HavenFailure>();
  final Rxn<PolicyEvaluationResult> lastEvaluation =
      Rxn<PolicyEvaluationResult>();
  ChildPolicyRecord? _active;
  ChildPolicyRecord? _lastValid;
  HavenFailure? _lastUsageFailure;
  UsagePermissionStatus? _lastUsagePermissionStatus;
  int _policyGeneration = 0;
  int _evaluationGeneration = 0;
  bool _disposed = false;

  ChildPolicyRecord? get lastValidPolicy => _lastValid;
  HavenFailure? get lastUsageFailure => _lastUsageFailure;
  UsagePermissionStatus? get lastUsagePermissionStatus =>
      _lastUsagePermissionStatus;
  bool get isDisposed => _disposed || isClosed;
  @override
  void onInit() {
    super.onInit();
    unawaited(loadPolicy());
  }

  @override
  void onClose() {
    _disposed = true;
    _policyGeneration++;
    _evaluationGeneration++;
    _active = null;
    activePolicy.value = null;
    policyFailure.value = null;
    lastEvaluation.value = null;
    _clearUsageDiagnostics();
    super.onClose();
  }

  Future<Result<void>> loadPolicy() async {
    if (isDisposed) {
      return _failure(
        'Policy controller disposed',
        'policy_controller_disposed',
      );
    }
    final generation = ++_policyGeneration;
    _evaluationGeneration++;
    status.value = ChildPolicyStatus.loading;
    activePolicy.value = null;
    _active = null;
    policyFailure.value = null;
    lastEvaluation.value = null;
    _clearUsageDiagnostics();

    final result = await policyRepository.getPolicy();
    if (isDisposed) {
      return _failure(
        'Policy controller disposed',
        'policy_controller_disposed',
      );
    }
    if (generation != _policyGeneration) {
      return _failure('Policy load superseded', 'policy_evaluation_refused');
    }
    if (result case Ok<ChildPolicyRecord>(:final value)) {
      _active = value;
      _lastValid = value;
      activePolicy.value = value;
      status.value = ChildPolicyStatus.ready;
      return okVoid();
    }
    _active = null;
    policyFailure.value = result.failureOrNull!;
    status.value = ChildPolicyStatus.failure;
    return Err<void>(result.failureOrNull!);
  }

  Future<Result<PolicyEvaluationResult>> evaluate() async {
    if (isDisposed) {
      return _evalFailure('Controller disposed', 'policy_controller_disposed');
    }
    if (status.value == ChildPolicyStatus.initial ||
        status.value == ChildPolicyStatus.loading) {
      return _evalFailure('Policy is not ready', 'policy_not_ready');
    }
    final record = _active;
    if (status.value != ChildPolicyStatus.ready || record == null) {
      return _evalFailure(
        'Policy evaluation refused',
        'policy_evaluation_refused',
      );
    }
    final evaluationId = ++_evaluationGeneration;
    final policyGeneration = _policyGeneration;
    final evaluationTime = clock.now();
    final range = PolicyUsageAdapter.dailyRange(evaluationTime);
    _clearUsageDiagnostics();
    final probe = await usageRepository.getPermissionStatus();
    if (_isStale(evaluationId, policyGeneration)) return _staleFailure();
    PolicyUsageSnapshot usage;
    HavenFailure? usageFailure;
    UsagePermissionStatus? permissionStatus;
    var permissionGranted = false;
    if (probe case Ok<UsagePermissionResult>(:final value)) {
      permissionStatus = value.status;
      if (value.status == UsagePermissionStatus.granted) {
        permissionGranted = true;
        if (range.start < range.end) {
          final result = await usageRepository.getDailyUsage(
            startTimeMillis: range.start,
            endTimeMillis: range.end,
          );
          if (_isStale(evaluationId, policyGeneration)) return _staleFailure();
          if (result case Ok<UsageDailyResult>(:final value)) {
            final converted = PolicyUsageAdapter.fromDailyResult(
              value,
              isPermissionGranted: true,
            );
            if (converted case Err<PolicyUsageSnapshot>(:final failure)) {
              return _evalFailure(
                'Policy evaluation refused: ${failure.message}',
                'policy_evaluation_refused',
              );
            }
            usage = converted.valueOrNull!;
          } else {
            usageFailure = result.failureOrNull;
            permissionGranted = usageFailure is! DevicePermissionFailure;
            usage = _unavailable(range, permissionGranted);
          }
        } else {
          usage = _unavailable(range, true);
        }
      } else {
        usage = _unavailable(range, false);
      }
    } else {
      usageFailure = probe.failureOrNull;
      usage = _unavailable(range, false);
    }
    if (_isStale(evaluationId, policyGeneration)) return _staleFailure();
    final evaluation = PolicyEvaluator.evaluate(
      context: record.toEvaluationContext(evaluationTime: evaluationTime),
      usage: usage,
    );
    _lastUsageFailure = usageFailure;
    _lastUsagePermissionStatus = permissionStatus;
    lastEvaluation.value = evaluation;
    return Ok<PolicyEvaluationResult>(evaluation);
  }

  bool _isStale(int evaluationId, int policyGeneration) =>
      isDisposed ||
      evaluationId != _evaluationGeneration ||
      policyGeneration != _policyGeneration;
  void _clearUsageDiagnostics() {
    _lastUsageFailure = null;
    _lastUsagePermissionStatus = null;
  }

  PolicyUsageSnapshot _unavailable(
    ({int start, int end}) range,
    bool isPermissionGranted,
  ) => PolicyUsageAdapter.unavailableForQuery(
    startTimeMillis: range.start,
    endTimeMillis: range.end,
    isPermissionGranted: isPermissionGranted,
  );
  Result<void> _failure(String message, String detail) =>
      Err<void>(UnknownFailure(message, detail: detail));
  Result<PolicyEvaluationResult> _evalFailure(String message, String detail) =>
      Err<PolicyEvaluationResult>(UnknownFailure(message, detail: detail));
  Result<PolicyEvaluationResult> _staleFailure() => isDisposed
      ? _evalFailure('Controller disposed', 'policy_controller_disposed')
      : _evalFailure('Policy evaluation refused', 'policy_evaluation_refused');
}
