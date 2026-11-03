import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/app/theme/haven_colors.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../support/host.dart';

/// "The specification is missing" is not a fault the parent caused, so blocked
/// has its own tone — and the words always carry the meaning on their own.
void main() {
  testWidgets('blocked reads as blocked, and is deliberately not red', (
    tester,
  ) async {
    await tester.pumpWidget(
      widgetHost(
        const StatusChip(label: 'Not available yet', tone: StatusTone.blocked),
      ),
    );

    final Text text = tester.widget(find.text('Not available yet'));
    expect(text.style?.color, HavenColors.blocked);
    expect(text.style?.color, isNot(HavenColors.bad));
  });

  testWidgets('every tone has a dark colour as well as a light one', (
    tester,
  ) async {
    for (final StatusTone tone in StatusTone.values) {
      await tester.pumpWidget(
        widgetHost(
          StatusChip(label: tone.name, tone: tone),
          brightness: Brightness.dark,
        ),
      );
      await tester.pump();

      final Text text = tester.widget(find.text(tone.name));
      expect(text.style?.color, isNotNull, reason: '$tone has no dark colour');
    }
  });

  testWidgets('the label is the signal, not the colour alone', (tester) async {
    await tester.pumpWidget(
      widgetHost(const StatusChip(label: 'Offline', tone: StatusTone.warning)),
    );

    expect(find.text('Offline'), findsOneWidget);
  });
}
