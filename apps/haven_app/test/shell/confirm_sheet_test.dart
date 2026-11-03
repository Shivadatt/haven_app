import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../support/host.dart';

/// Anything that removes a device, unlinks a child or ends a session asks first,
/// and anything other than an explicit "yes" is a no.
void main() {
  Future<bool> open(
    WidgetTester tester, {
    bool destructive = false,
    String? tap,
  }) async {
    var answer = true;
    await tester.pumpWidget(
      widgetHost(
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async {
              answer = await ConfirmSheet.confirm(
                context,
                title: 'Unlink this child?',
                body: 'Their devices stop reporting to you.',
                confirmLabel: 'Unlink',
                destructive: destructive,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(tap ?? 'Cancel'));
    await tester.pumpAndSettle();
    return answer;
  }

  testWidgets('cancel is a no', (tester) async {
    expect(await open(tester), isFalse);
  });

  testWidgets('confirming runs the action', (tester) async {
    final bool answer = await open(tester, tap: 'Unlink');
    expect(answer, isTrue);
  });

  testWidgets('dismissing the dialog is a no', (tester) async {
    var answer = true;
    await tester.pumpWidget(
      widgetHost(
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async {
              answer = await ConfirmSheet.confirm(
                context,
                title: 'Remove this device?',
                body: 'Monitoring stops immediately.',
                confirmLabel: 'Remove device',
                destructive: true,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(answer, isFalse);
  });

  testWidgets('a destructive confirm labels the action in its own words', (
    tester,
  ) async {
    await tester.pumpWidget(
      widgetHost(
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => ConfirmSheet.confirm(
              context,
              title: 'End the session?',
              body: 'The screen share stops.',
              confirmLabel: 'End session',
              destructive: true,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('End session'), findsOneWidget);
    expect(find.text('OK'), findsNothing);
  });
}
