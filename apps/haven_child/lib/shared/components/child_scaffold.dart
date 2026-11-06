import 'package:flutter/material.dart';

import '../../app/theme/child_spacing.dart';

/// The single page frame for the child app: consistent app bar, safe area and
/// a back button whenever there is somewhere to go back to. The child
/// counterpart of the parent's `HavenScaffold`.
///
/// Unlike the parent there is no backend banner: Stage 1 declares no network,
/// so a banner would be decoration. EXTENSION POINT (Agent 2): if a later
/// stage adds a connection state, surface it through a real component here,
/// not through per-screen widgets.
final class ChildScaffold extends StatelessWidget {
  const ChildScaffold({
    required this.title,
    required this.body,
    this.actions = const [],
    this.showBack = true,
    this.bottomBar,
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final bool showBack;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final bool canPop = showBack && Navigator.of(context).canPop();
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: canPop ? const BackButton() : null,
        automaticallyImplyLeading: canPop,
        actions: actions,
      ),
      body: SafeArea(child: body),
      bottomNavigationBar: bottomBar,
    );
  }
}

/// A page body with the standard gutter and a max content width, so no screen
/// sets its own padding — the child counterpart of `HavenPageBody`.
class ChildPageBody extends StatelessWidget {
  const ChildPageBody({required this.child, this.maxWidth = 720, super.key});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ChildSpacing.gutter),
        child: child,
      ),
    ),
  );
}
