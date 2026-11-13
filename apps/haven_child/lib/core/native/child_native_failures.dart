import 'package:haven_core/haven_core.dart';

import 'child_native_contract.dart';
import 'child_native_registry.dart';

/// A Kotlin error code, mapped onto the failure vocabulary the rest of Haven uses.
///
/// Never an exception, never a silent default: an unknown code stays unknown and
/// says which code it was. Split from `child_native_envelope.dart` to stay
/// inside the repo's 200-line source rule.
HavenFailure childNativeFailureFor({
  required String code,
  String? message,
  String? section,
}) {
  final String context = message == null ? code : '$code: $message';
  if (code == ChildNativeErrorCode.unknownMethod) {
    return ValidationFailure(
      'The native lane does not answer that request.',
      field: 'native_method',
      detail: context,
    );
  }
  if (code == ChildNativeErrorCode.noContext) {
    return UnknownFailure(
      'The phone had no running app to ask.',
      detail: context,
    );
  }
  if (code == ChildNativeErrorCode.sectionFailed) {
    return BackendFailure(
      'The phone could not read that part of the device.',
      code: ChildNativeErrorCode.sectionFailed,
      detail: section == null ? context : '$context section=$section',
      retryable: true,
    );
  }
  return UnknownFailure(
    'The native lane gave a reason this build does not know.',
    detail: 'unmapped_error_code: $context',
  );
}

/// The child's honest answer for any use of this surface in this build.
///
/// Not a fabricated empty report: `blocked(...)` keeps the claim out of the UI.
/// A future child lane replaces this call at the seam, not in a screen.
Result<T> blockedChildNativeLane<T>() => blocked<T>(
  '${ChildNativeKotlinSource.androidNativeRoot} is compiled by the parent app '
  'only, so this child build has no native device-state reader to call',
  requirement: ChildNativeContract.laneAvailabilityNote,
);
