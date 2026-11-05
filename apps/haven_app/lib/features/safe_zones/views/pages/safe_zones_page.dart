import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/zones_controller.dart';
import '../../data/zones_models.dart';
import '../widgets/zones_card.dart';

/// The places this family named, and the two things it can and cannot do with
/// them.
final class SafeZonesPage extends GetView<SafeZonesController> {
  const SafeZonesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Safe places',
      onRefresh: controller.reload,
      body: HavenPageBody(
        child: Obx(
          () => StateView<ZoneBoard?>(
            isLoading: controller.isLoading.value,
            result: controller.board.value,
            onRetry: controller.load,
            empty: () => const _NeedsSetup(),
            onData: (BuildContext context, ZoneBoard? board) =>
                _Content(board!),
          ),
        ),
      ),
    );
  }
}

class _Content extends GetView<SafeZonesController> {
  const _Content(this.board);

  final ZoneBoard board;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ZonesCard(
          board: board,
          onEdit: controller.goToEditor,
          onCreate: controller.goToCreate,
        ),
        if (!board.isOffline) ...[
          const SizedBox(height: HavenSpacing.md),
          const ZonesLimitsCard(),
        ],
      ],
    ),
  );
}

/// What a parent can actually change, said before they look for a button.
final class ZonesLimitsCard extends StatelessWidget {
  const ZonesLimitsCard({super.key});

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'What you can change about a place',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A place that already exists can be renamed, moved to different '
          'coordinates, made wider or tighter, paused, or removed. Naming a '
          'place that does not exist yet is not one of them: the database lets a '
          'parent change a place but not create one, so there is no add button '
          'here to press.',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.sm),
        Text(
          'Moving a place means typing the coordinates. This build has no map to '
          'tap a point on.',
          style: HavenText.caption.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class _NeedsSetup extends GetView<SafeZonesController> {
  const _NeedsSetup();

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Haven is not set up yet',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Places belong to a family. With no family for this account, there is '
          'nothing for this screen to read.',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.md),
        HavenButton(label: 'Start setup', onPressed: controller.goToSetup),
      ],
    ),
  );
}
