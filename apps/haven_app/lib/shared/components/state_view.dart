import 'package:flutter/material.dart';
import 'package:haven_core/haven_core.dart';

import '../../app/theme/haven_spacing.dart';
import '../../app/theme/haven_text.dart';
import 'blocked_notice.dart';
import 'haven_button.dart';

/// The one place a data screen decides what "still loading", "failed", "not
/// specified", "nothing there" and "here it is" look like.
///
/// Every feature uses this instead of its own if-chain, so a blocked feature
/// reads identically everywhere and can never be rendered as a fake value.
final class StateView<T> extends StatelessWidget {
  const StateView({
    required this.isLoading,
    required this.result,
    required this.onData,
    this.emptyMessage = 'Nothing here yet',
    this.empty,
    this.onRetry,
    this.padding = const EdgeInsets.all(HavenSpacing.md),
    super.key,
  });

  final bool isLoading;
  final Result<T>? result;
  final Widget Function(BuildContext context, T data) onData;
  final String emptyMessage;
  final Widget Function()? empty;
  final VoidCallback? onRetry;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(HavenSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final Result<T>? value = result;
    if (value == null) return _emptyBody(context);

    final HavenFailure? failure = value.failureOrNull;
    if (failure != null) {
      return SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (failure is BlockedFailure)
              BlockedNotice(
                requirement: failure.message,
                missing: failure.missing,
              )
            else
              _ErrorBody(failure: failure, onRetry: onRetry),
          ],
        ),
      );
    }

    final T? data = value.valueOrNull;
    if (data == null || _isEmpty(data)) return _emptyBody(context);
    return onData(context, data);
  }

  Widget _emptyBody(BuildContext context) => Padding(
    padding: padding,
    child:
        empty?.call() ??
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              emptyMessage,
              style: HavenText.body.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: HavenSpacing.md),
              HavenButton(
                label: 'Try again',
                onPressed: onRetry,
                primary: false,
              ),
            ],
          ],
        ),
  );

  static bool _isEmpty(Object data) =>
      (data is List && data.isEmpty) || (data is Map && data.isEmpty);
}

final class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.failure, this.onRetry});

  final HavenFailure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(failure.message, style: HavenText.body),
        if (failure.retryable && onRetry != null) ...[
          const SizedBox(height: HavenSpacing.md),
          HavenButton(label: 'Try again', onPressed: onRetry),
        ],
      ],
    );
  }
}
