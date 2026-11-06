import 'package:flutter/material.dart';

import '../../shared/components/child_scaffold.dart';
import '../../shared/components/state_view.dart';

/// Where an unlisted route name lands. Mirrors the parent's `NotFoundPage`
/// policy: say the screen is not built, never show a half-blank invention.
final class UnknownPage extends StatelessWidget {
  const UnknownPage({super.key});

  @override
  Widget build(BuildContext context) => const ChildScaffold(
    title: 'Haven Child',
    body: ChildPageBody(
      child: ChildStateView<void>(
        emptyMessage: 'This screen is not part of the child app yet.',
      ),
    ),
  );
}
