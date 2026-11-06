import 'package:flutter/material.dart';
import 'package:haven_core/haven_core.dart';

import '../../app/theme/child_spacing.dart';
import '../../app/theme/child_text.dart';
import 'blocked_notice.dart';

/// The one place a child screen decides what "still loading", "failed", "not
/// built yet", "nothing there" and "here it is" look like.
///
/// Stage 2 of this component (Agent 2, Phase 3 Stage 1) gave it the parent's
/// `Result<T>`-shaped input, so a [BlockedFailure] renders the same refusal
/// vocabulary everywhere and can never be shown as a fabricated value. The
/// original `errorMessage` channel is kept for text-only states, and it
/// carries plain user-facing text only — never a stack.
final class ChildStateView<T> extends StatelessWidget {
  const ChildStateView({
    required this.emptyMessage,
    this.isLoading = false,
    this.errorMessage,
    this.result,
    this.data,
    this.onData,
    this.empty,
    this.onRetry,
    this.showRetryOnError = true,
    this.padding = const EdgeInsets.all(ChildSpacing.md),
    super.key,
  });

  final bool isLoading;

  /// Plain-text failure channel (no Result involved), e.g. controller-level
  /// "setup could not start" copy.
  final String? errorMessage;

  /// The typed outcome when a repository call drives this screen.
  final Result<T>? result;

  final T? data;
  final Widget Function(BuildContext context, T data)? onData;
  final String emptyMessage;

  /// Custom empty body — e.g. the "finish setup" prompt when no profile row
  /// exists yet. Mirrors the parent's `StateView.empty`.
  final Widget Function()? empty;

  final VoidCallback? onRetry;

  /// A non-retryable failure (a missing implementation, a refused write)
  /// renders its message without a "Try again" button pretending otherwise.
  final bool showRetryOnError;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(ChildSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final Result<T>? typed = result;
    if (typed != null) {
      final HavenFailure? failure = typed.failureOrNull;
      if (failure != null) return _failureBody(context, failure);
      final T? value = typed.valueOrNull;
      if (value == null || _isEmpty(value)) return _emptyBody(context);
      return onData?.call(context, value) ?? _emptyBody(context);
    }

    final String? failure = errorMessage;
    if (failure != null) {
      return _errorText(context, failure, retryable: showRetryOnError);
    }

    final T? value = data;
    if (value == null || _isEmpty(value) || onData == null) {
      return _emptyBody(context);
    }
    return onData!(context, value);
  }

  Widget _failureBody(BuildContext context, HavenFailure failure) {
    if (failure is BlockedFailure) {
      return SingleChildScrollView(
        padding: padding,
        child: ChildBlockedNotice(
          requirement: failure.message,
          missing: failure.missing,
        ),
      );
    }
    return _errorText(
      context,
      failure.message,
      retryable: failure.retryable && onRetry != null,
    );
  }

  Widget _errorText(BuildContext context, String text, {required bool retryable}) =>
      SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, style: ChildText.body),
            if (retryable && onRetry != null) ...[
              const SizedBox(height: ChildSpacing.md),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      );

  Widget _emptyBody(BuildContext context) => Padding(
    padding: padding,
    child:
        empty?.call() ??
        Text(
          emptyMessage,
          style: ChildText.body.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
  );

  static bool _isEmpty(Object value) =>
      (value is List && value.isEmpty) || (value is Map && value.isEmpty);
}
