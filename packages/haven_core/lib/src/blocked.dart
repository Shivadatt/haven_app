import 'failures.dart';
import 'result.dart';

/// Returns the one honest outcome for behaviour the requirements documents do
/// not specify, rather than inventing a rule or a fake success.
///
/// Call this at the seam, keep the surrounding interface typed, and name exactly
/// what is missing (a specification section, a signed approval, a schema column).
Result<T> blocked<T>(String missing, {String? requirement}) => Err<T>(
      BlockedFailure(
        requirement ?? "This isn't specified yet, so Haven won't guess.",
        missing: missing,
        detail: 'BLOCKED — SPECIFICATION REQUIRED: $missing',
      ),
    );

/// Thrown nowhere: used by view code that must render the blocked state.
bool isBlocked(Result<Object?> result) => result is Err<Object?> && result.failure is BlockedFailure;
