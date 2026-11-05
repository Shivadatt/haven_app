import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/session_detail_controller.dart';
import '../../data/session_detail_models.dart';
import '../widgets/session_detail_card.dart';

/// One session record, read in full.
final class RemoteSessionDetailPage extends GetView<SessionDetailController> {
  const RemoteSessionDetailPage({super.key});

  @override
  Widget build(BuildContext context) => HavenScaffold(
    title: 'Session record',
    onRefresh: controller.reload,
    body: HavenPageBody(
      child: Obx(
        () => StateView<SessionDetail?>(
          isLoading: controller.isLoading.value,
          result: controller.detail.value,
          onRetry: controller.load,
          empty: () => const _NeedsSetup(),
          onData: (BuildContext context, SessionDetail? detail) =>
              _Content(detail!, carriesMedia: controller.carriesMedia),
        ),
      ),
    ),
  );
}

class _Content extends StatelessWidget {
  const _Content(this.detail, {required this.carriesMedia});

  final SessionDetail detail;
  final bool carriesMedia;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SessionDetailCard(detail: detail),
        const SizedBox(height: HavenSpacing.md),
        SessionMediaCard(detail: detail, carriesMedia: carriesMedia),
      ],
    ),
  );
}

/// The route was opened with no family behind this account, so there is no
/// session record to read.
class _NeedsSetup extends GetView<SessionDetailController> {
  const _NeedsSetup();

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Haven is not set up yet',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sessions belong to a family. With no family for this account there '
          'is no record for this screen to read.',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.md),
        HavenButton(label: 'Start setup', onPressed: controller.goToSetup),
      ],
    ),
  );
}
