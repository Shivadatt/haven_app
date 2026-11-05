import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/pairing_controller.dart';
import '../../data/pairing_models.dart';
import '../widgets/pairing_simulation_card.dart';
import '../widgets/requests_card.dart';

/// Pairing, as far as this build can take it: the requests the backend will show
/// this parent, and the one road onward that actually leads somewhere.
final class PairingPage extends GetView<PairingController> {
  const PairingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Pairing',
      onRefresh: controller.reload,
      body: HavenPageBody(
        child: Obx(
          () => StateView<PairingBoard?>(
            isLoading: controller.isLoading.value,
            result: controller.board.value,
            onRetry: controller.load,
            empty: () => const _NeedsSetup(),
            onData: (BuildContext context, PairingBoard? board) =>
                _Content(board!),
          ),
        ),
      ),
    );
  }
}

class _Content extends GetView<PairingController> {
  const _Content(this.board);

  final PairingBoard board;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PairingSimulationCard(onOpenSimulation: controller.goToSimulation),
          const SizedBox(height: HavenSpacing.md),
          Obx(
            () => RequestsCard(
              board: board,
              withdrawalGap: controller.cancelGap.value,
            ),
          ),
          const SizedBox(height: HavenSpacing.md),
          const _StartCard(),
        ],
      ),
    );
  }
}

/// The route to the screen that states what a pairing needs and why this build
/// cannot do it. It is a real page, so the button is real.
class _StartCard extends GetView<PairingController> {
  const _StartCard();

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Pair a new device',
    subtitle: "Two ways a child's phone joins Haven, and what each needs.",
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A child can show a short code from their own device, or a parent can '
          'start an invite for the Child ID printed on it. Haven explains both '
          'and what this build is missing before either can be started.',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.md),
        HavenButton(
          label: 'How pairing works',
          primary: false,
          onPressed: controller.goToCode,
        ),
      ],
    ),
  );
}

class _NeedsSetup extends GetView<PairingController> {
  const _NeedsSetup();

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Haven is not set up yet',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pairing belongs to a family. Set yours up first and this screen will '
          'have something to say.',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.md),
        HavenButton(label: 'Start setup', onPressed: controller.goToSetup),
      ],
    ),
  );
}
