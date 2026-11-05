import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/location_controller.dart';
import '../../data/location_models.dart';
import '../widgets/fix_card.dart';

/// The places the family's devices reported, and the boundaries of that read.
final class LocationPage extends GetView<LocationController> {
  const LocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Reported places',
      onRefresh: controller.reload,
      body: HavenPageBody(
        child: Obx(
          () => StateView<FixBoard?>(
            isLoading: controller.isLoading.value,
            result: controller.board.value,
            onRetry: controller.load,
            empty: () => const _NeedsSetup(),
            onData: (BuildContext context, FixBoard? board) => _Content(board!),
          ),
        ),
      ),
    );
  }
}

class _Content extends GetView<LocationController> {
  const _Content(this.board);

  final FixBoard board;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FixCard(
                board: board,
                showsCoordinates: controller.showsCoordinates.value,
              ),
              if (board.hasLines) ...[
                const SizedBox(height: HavenSpacing.md),
                HavenButton(
                  label: controller.showsCoordinates.value
                      ? 'Hide the exact coordinates'
                      : 'Show the exact coordinates',
                  primary: false,
                  onPressed: controller.toggleCoordinates,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: HavenSpacing.md),
        LocationLimitsCard(board: board),
      ],
    ),
  );
}

class _NeedsSetup extends GetView<LocationController> {
  const _NeedsSetup();

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Haven is not set up yet',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Places are reported by a device into a family. With no family for this '
          'account, there is nothing for this screen to read.',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.md),
        HavenButton(label: 'Start setup', onPressed: controller.goToSetup),
      ],
    ),
  );
}
