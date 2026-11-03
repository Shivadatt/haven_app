import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_core/haven_core.dart';

import '../support/host.dart';

/// `StateView` is the single decision point every data screen shares: loading,
/// failed, blocked, empty, here-it-is. A fake value must never render.
void main() {
  StateView<List<String>> view({
    bool loading = false,
    Result<List<String>>? result,
    String emptyMessage = 'Nothing here yet',
    VoidCallback? onRetry,
  }) => StateView<List<String>>(
    isLoading: loading,
    result: result,
    emptyMessage: emptyMessage,
    onRetry: onRetry,
    onData: (_, data) => Text('rows: ${data.length}'),
  );

  testWidgets('loading shows progress and no data', (tester) async {
    await tester.pumpWidget(
      widgetHost(view(loading: true, result: const Ok(['a']))),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('rows: 1'), findsNothing);
  });

  testWidgets('data wins once loading is over', (tester) async {
    await tester.pumpWidget(widgetHost(view(result: const Ok(['a', 'b']))));

    expect(find.text('rows: 2'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('an empty collection reads as empty, not as zero', (
    tester,
  ) async {
    await tester.pumpWidget(widgetHost(view(result: const Ok([]))));

    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.text('rows: 0'), findsNothing);
  });

  testWidgets('no result at all is the same empty state', (tester) async {
    await tester.pumpWidget(widgetHost(view(result: null)));

    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  testWidgets('the caller can supply its own empty copy', (tester) async {
    await tester.pumpWidget(
      widgetHost(
        StateView<List<String>>(
          isLoading: false,
          result: const Ok([]),
          empty: () => const Text('No devices paired yet'),
          onData: (_, data) => Text('rows: ${data.length}'),
        ),
      ),
    );

    expect(find.text('No devices paired yet'), findsOneWidget);
    expect(find.text('Nothing here yet'), findsNothing);
  });

  testWidgets('a blocked feature renders the notice, never the data', (
    tester,
  ) async {
    await tester.pumpWidget(
      widgetHost(
        view(result: blocked<List<String>>('safe zone dwell semantics')),
      ),
    );

    expect(find.byType(BlockedNotice), findsOneWidget);
    expect(find.textContaining('safe zone dwell semantics'), findsOneWidget);
    expect(find.text('rows: 0'), findsNothing);
  });

  testWidgets('a retryable failure offers one retry', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      widgetHost(
        view(
          result: const Err<List<String>>(
            NetworkFailure('The network dropped.'),
          ),
          onRetry: () => taps++,
        ),
      ),
    );

    expect(find.text('The network dropped.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(taps, 1);
  });

  testWidgets('a failure that cannot be retried does not offer a retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      widgetHost(
        view(
          result: const Err<List<String>>(
            PermissionFailure('This account cannot see that.'),
          ),
          onRetry: () {},
        ),
      ),
    );

    expect(find.text('Try again'), findsNothing);
  });
}
