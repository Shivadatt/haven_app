import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/family_controller.dart';
import '../../data/family_models.dart';
import '../widgets/people_card.dart';

/// Who is in this family and what the family is called.
final class FamilyPage extends GetView<FamilyController> {
  const FamilyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Your family',
      body: HavenPageBody(
        child: Obx(
          () => StateView<FamilyBundle?>(
            isLoading: controller.isLoading.value,
            result: controller.family.value,
            onRetry: controller.load,
            empty: () => const _NeedsSetup(),
            onData: (BuildContext context, FamilyBundle? bundle) =>
                _Content(bundle!),
          ),
        ),
      ),
    );
  }
}

class _Content extends GetView<FamilyController> {
  const _Content(this.bundle);

  final FamilyBundle bundle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NameCard(),
          const SizedBox(height: HavenSpacing.md),
          PeopleCard(
            title: 'Children',
            people: bundle.children,
            emptyLine:
                'No children are in this family yet. A child joins when you '
                'pair their device.',
            onTap: controller.goToChild,
          ),
          const SizedBox(height: HavenSpacing.md),
          PeopleCard(
            title: 'Parents',
            people: bundle.parents,
            emptyLine: 'This family has no other parent.',
          ),
          const SizedBox(height: HavenSpacing.md),
          _Gaps(),
        ],
      ),
    );
  }
}

class _NameCard extends GetView<FamilyController> {
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Family name',
      subtitle: "Your children's devices show this name.",
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HavenField(
              label: 'Name',
              controller: controller.familyName,
              maxLength: 80,
              enabled: !controller.busy.value,
            ),
            const SizedBox(height: HavenSpacing.md),
            if (controller.message.value != null) ...[
              Text(controller.message.value!, style: HavenText.body),
              const SizedBox(height: HavenSpacing.sm),
            ],
            HavenButton(
              label: 'Save name',
              busy: controller.busy.value,
              onPressed: controller.canSave ? controller.save : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// The two membership changes this build cannot make, in the repository's own
/// words — so the screen has no dead control and no invented promise.
class _Gaps extends GetView<FamilyController> {
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Not available in Haven yet',
      subtitle: 'These need a backend contract nobody has approved.',
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.inviteParent.value != null)
              Padding(
                padding: const EdgeInsets.only(bottom: HavenSpacing.sm),
                child: BlockedNotice.fromFailure(
                  controller.inviteParent.value!,
                ),
              ),
            if (controller.removeParent.value != null)
              BlockedNotice.fromFailure(controller.removeParent.value!),
          ],
        ),
      ),
    );
  }
}

class _NeedsSetup extends GetView<FamilyController> {
  const _NeedsSetup();

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'This account has no family yet',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Haven keeps your children, their devices and your rules inside one '
          'family. Setup creates it.',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.md),
        HavenButton(label: 'Set up Haven', onPressed: controller.goToSetup),
      ],
    ),
  );
}
