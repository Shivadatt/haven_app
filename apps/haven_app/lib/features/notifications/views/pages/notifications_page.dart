import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/notifications_controller.dart';
import '../../data/alerts_models.dart';
import '../widgets/report_card.dart';

/// The reports the backend has written for this family, read-only.
final class NotificationsPage extends GetView<NotificationsController> {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) => HavenScaffold(
    title: 'Reports',
    onRefresh: controller.reload,
    body: HavenPageBody(
      child: Obx(
        () => StateView<AlertBoard?>(
          isLoading: controller.isLoading.value,
          result: controller.board.value,
          onRetry: controller.load,
          empty: () => const _NeedsSetup(),
          onData: (BuildContext context, AlertBoard? board) => _Content(
            board!,
            canRegister: controller.deviceIsRegistered,
            onOpenSettings: controller.goToSettings,
          ),
        ),
      ),
    ),
  );
}

class _Content extends StatelessWidget {
  const _Content(
    this.board, {
    required this.canRegister,
    required this.onOpenSettings,
  });

  final AlertBoard board;
  final bool canRegister;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReportListCard(board: board),
        const SizedBox(height: HavenSpacing.md),
        ReportLimitsCard(
          board: board,
          canRegister: canRegister,
          onOpenSettings: onOpenSettings,
        ),
      ],
    ),
  );
}

/// The route was opened with no family behind this account, so there are no
/// reports to read.
class _NeedsSetup extends GetView<NotificationsController> {
  const _NeedsSetup();

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Haven is not set up yet',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A report is written about a device in a family. With no family for '
          'this account there is nothing for this screen to read.',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.md),
        HavenButton(label: 'Start setup', onPressed: controller.goToSetup),
      ],
    ),
  );
}
