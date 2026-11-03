import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../support/host.dart';

/// The app's only button: a screen that cannot act passes a null action and the
/// button reads as disabled, instead of looking tappable and then doing nothing.
void main() {
  testWidgets('a null action renders disabled, not tappable-then-silent', (
    tester,
  ) async {
    await tester.pumpWidget(
      widgetHost(const HavenButton(label: 'Pair a device', onPressed: null)),
    );

    final FilledButton button = tester.widget(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('busy blocks re-entry so one tap sends one command', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      widgetHost(
        HavenButton(label: 'Send', onPressed: () => taps++, busy: true),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final FilledButton button = tester.widget(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(taps, 0);
  });

  testWidgets('an idle button acts once per tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      widgetHost(HavenButton(label: 'Send', onPressed: () => taps++)),
    );

    await tester.tap(find.text('Send'));
    expect(taps, 1);
  });

  testWidgets('secondary is outlined so a screen keeps one primary action', (
    tester,
  ) async {
    await tester.pumpWidget(
      widgetHost(
        const HavenButton(label: 'Cancel', onPressed: _none, primary: false),
      ),
    );

    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });
}

void _none() {}
