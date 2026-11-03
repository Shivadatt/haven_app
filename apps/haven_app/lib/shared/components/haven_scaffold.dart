import 'package:flutter/material.dart';

import '../../app/theme/haven_spacing.dart';
import 'backend_banner.dart';

/// The single page frame. Consistent gutter, one title, the backend banner on
/// every data screen, and a back button whenever there is somewhere to go back
/// to — so navigation never depends on remembering which pages have one.
final class HavenScaffold extends StatelessWidget {
  const HavenScaffold({
    required this.title,
    required this.body,
    this.actions = const [],
    this.fab,
    this.showBackendBanner = true,
    this.showBack = true,
    this.bottomBar,
    this.onRefresh,
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? fab;

  /// Off only on the pages that are themselves about the connection.
  final bool showBackendBanner;
  final bool showBack;
  final Widget? bottomBar;

  /// Pull-to-refresh, where the screen is a live view of the backend.
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final bool canPop = showBack && Navigator.of(context).canPop();
    final Widget content = Column(
      children: [
        if (showBackendBanner) const BackendBanner(),
        Expanded(
          child: onRefresh == null
              ? body
              : RefreshIndicator(onRefresh: onRefresh!, child: body),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: canPop ? const BackButton() : null,
        automaticallyImplyLeading: canPop,
        actions: actions,
      ),
      body: SafeArea(child: content),
      floatingActionButton: fab,
      bottomNavigationBar: bottomBar,
    );
  }
}

/// A page body with the standard gutter, so no screen sets its own padding.
class HavenPageBody extends StatelessWidget {
  const HavenPageBody({required this.child, this.maxWidth = 720, super.key});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: HavenSpacing.gutter),
        child: child,
      ),
    ),
  );
}
