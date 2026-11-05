import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/activity_controller.dart';
import '../../data/activity_models.dart';
import '../widgets/activity_timeline_card.dart';
import '../widgets/usage_card.dart';

/// App use the family is permitted to read, and the reason the rows have no
/// owner named on them yet.
final class ActivityPage extends GetView<ActivityController> {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Usage activity',
      onRefresh: controller.reload,
      body: HavenPageBody(
        child: Obx(
          () => StateView<UsageBoard?>(
            isLoading: controller.isLoading.value,
            result: controller.board.value,
            onRetry: controller.load,
            empty: () => const _NeedsSetup(),
            onData: (BuildContext context, UsageBoard? board) =>
                _Content(board!),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content(this.board);

  final UsageBoard board;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UsageCard(board: board),
        if (board.isOffline || board.hasEvents) ...[
          const SizedBox(height: HavenSpacing.md),
          ActivityTimelineCard(board: board),
        ],
        const SizedBox(height: HavenSpacing.md),
        const UsageLimitsCard(),
      ],
    ),
  );
}

class _NeedsSetup extends GetView<ActivityController> {
  const _NeedsSetup();

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Haven is not set up yet',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Usage is reported by a device into a family. With no family for this '
          'account, there is nothing for this screen to read.',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.md),
        HavenButton(label: 'Start setup', onPressed: controller.goToSetup),
      ],
    ),
  );
}
