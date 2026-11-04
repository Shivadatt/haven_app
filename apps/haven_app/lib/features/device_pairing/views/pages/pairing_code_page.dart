import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/pairing_code_controller.dart';
import '../../data/pairing_models.dart';

/// What pairing would take, stated against what the evidence actually says.
///
/// There is no code box here and no invite button, because a control that can
/// only ever be refused is the one thing §2 of the build contract forbids. The
/// refusals are the repository's own, so the missing contract is quoted rather
/// than paraphrased.
final class PairingCodePage extends GetView<PairingCodeController> {
  const PairingCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'How pairing works',
      body: HavenPageBody(
        child: Obx(
          () => StateView<PairingBoard?>(
            isLoading: controller.isLoading.value,
            result: controller.board.value,
            onRetry: controller.load,
            empty: () => const _NeedsSetup(),
            onData: (BuildContext context, PairingBoard? board) => _Content(),
          ),
        ),
      ),
    );
  }
}

class _Content extends GetView<PairingCodeController> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.isForAnotherFamily) ...[
            const _OtherFamilyCard(),
            const SizedBox(height: HavenSpacing.md),
          ],
          Obx(
            () => SectionCard(
              title: 'A short code from the phone',
              subtitle:
                  'The child starts pairing on their own device and types '
                  'the code it shows into Haven.',
              child: controller.codeGap.value == null
                  ? const SizedBox.shrink()
                  : BlockedNotice.fromFailure(controller.codeGap.value!),
            ),
          ),
          const SizedBox(height: HavenSpacing.md),
          Obx(
            () => SectionCard(
              title: 'An invite for a Child ID',
              subtitle:
                  "Haven would issue an invite for the stable Child ID "
                  'printed on the child\'s account.',
              child: controller.inviteGap.value == null
                  ? const SizedBox.shrink()
                  : BlockedNotice.fromFailure(controller.inviteGap.value!),
            ),
          ),
          const SizedBox(height: HavenSpacing.md),
          Text(
            'Either way the child approves on their own phone before anything '
            'is reported to Haven. Haven will not pair a device that nobody in '
            'the family has agreed to.',
            style: HavenText.caption,
          ),
        ],
      ),
    );
  }
}

/// The route carried a family id; the session resolved a different one. The
/// screen says so instead of quietly pairing into whichever family is current.
class _OtherFamilyCard extends GetView<PairingCodeController> {
  const _OtherFamilyCard();

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'This pairing screen was opened for another family',
    subtitle: 'Pairing would belong to ${controller.familyName}.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Go back to pairing and open it again from there, so the request is '
          'made for the family you are looking at.',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.md),
        HavenButton(
          label: 'Back to pairing',
          onPressed: controller.goToPairing,
        ),
      ],
    ),
  );
}

class _NeedsSetup extends GetView<PairingCodeController> {
  const _NeedsSetup();

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'There is no family to pair into yet',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set up Haven first. A device pairs into a family, so nothing here can '
          'go ahead until the family exists.',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.md),
        HavenButton(
          label: 'Back to pairing',
          onPressed: controller.goToPairing,
        ),
      ],
    ),
  );
}
