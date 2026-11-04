import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/commands_controller.dart';
import '../../data/commands_models.dart';
import '../widgets/command_card.dart';

/// The instructions written for this family's devices, read-only.
final class CommandsPage extends GetView<CommandsController> {
  const CommandsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Instructions',
      onRefresh: controller.refresh,
      body: HavenPageBody(
        child: Obx(
          () => StateView<CommandBoard?>(
            isLoading: controller.isLoading.value,
            result: controller.board.value,
            onRetry: controller.load,
            empty: () => const _NeedsSetup(),
            onData: (BuildContext context, CommandBoard? board) =>
                _Content(board!),
          ),
        ),
      ),
    );
  }
}

class _Content extends GetView<CommandsController> {
  const _Content(this.board);

  final CommandBoard board;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CommandCard(board: board),
        const SizedBox(height: HavenSpacing.md),
        CommandLimitsCard(board: board),
      ],
    ),
  );
}

/// The route was opened with no family behind this account, so there is no
/// instruction log to read.
class _NeedsSetup extends GetView<CommandsController> {
  const _NeedsSetup();

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Haven is not set up yet',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instructions belong to a device, and a device belongs to a family. '
          'With no family for this account, there is nothing for this screen '
          'to read.',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.md),
        HavenButton(label: 'Start setup', onPressed: controller.goToSetup),
      ],
    ),
  );
}
