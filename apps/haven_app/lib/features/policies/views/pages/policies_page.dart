import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/policies_controller.dart';
import '../../data/policies_models.dart';
import '../widgets/policy_card.dart';

/// The rule versions on record for this family's devices, read-only.
final class PoliciesPage extends GetView<PoliciesController> {
  const PoliciesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Rule versions',
      onRefresh: controller.refresh,
      body: HavenPageBody(
        child: Obx(
          () => StateView<PolicyBoard?>(
            isLoading: controller.isLoading.value,
            result: controller.board.value,
            onRetry: controller.load,
            empty: () => const _NeedsSetup(),
            onData: (BuildContext context, PolicyBoard? board) =>
                _Content(board!),
          ),
        ),
      ),
    );
  }
}

class _Content extends GetView<PoliciesController> {
  const _Content(this.board);

  final PolicyBoard board;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PolicyCard(board: board),
        const SizedBox(height: HavenSpacing.md),
        PolicyLimitsCard(board: board),
      ],
    ),
  );
}

/// No family behind this account, so there is no version list to read.
class _NeedsSetup extends GetView<PoliciesController> {
  const _NeedsSetup();

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Haven is not set up yet',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rule versions belong to a device, and a device belongs to a family. '
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
