import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/sessions_controller.dart';
import '../../data/sessions_models.dart';
import '../widgets/session_card.dart';

/// The session records this family may read.
final class RemoteSessionsPage extends GetView<SessionsController> {
  const RemoteSessionsPage({super.key});

  @override
  Widget build(BuildContext context) => HavenScaffold(
    title: 'Sessions',
    onRefresh: controller.reload,
    body: HavenPageBody(
      child: Obx(
        () => StateView<SessionBoard?>(
          isLoading: controller.isLoading.value,
          result: controller.board.value,
          onRetry: controller.load,
          empty: () => const _NeedsSetup(),
          onData: (BuildContext context, SessionBoard? board) =>
              _Content(board!, onOpen: controller.openDetail),
        ),
      ),
    ),
  );
}

class _Content extends StatelessWidget {
  const _Content(this.board, {required this.onOpen});

  final SessionBoard board;
  final void Function(String sessionId) onOpen;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SessionListCard(board: board, onOpen: onOpen),
        const SizedBox(height: HavenSpacing.md),
        SessionLimitsCard(board: board),
      ],
    ),
  );
}

/// The route was opened with no family behind this account, so there is no
/// session record to read.
class _NeedsSetup extends GetView<SessionsController> {
  const _NeedsSetup();

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Haven is not set up yet',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A session belongs to a device in a family. With no family for this '
          'account there is nothing for this screen to read.',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.md),
        HavenButton(label: 'Start setup', onPressed: controller.goToSetup),
      ],
    ),
  );
}
