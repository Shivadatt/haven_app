import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/family_controller.dart';
import '../../data/family_models.dart';
import '../dialogs/add_child_dialog.dart';
import '../widgets/family_gaps_card.dart';
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
                'pair their device or add their profile.',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  tooltip: 'Create child page',
                  onPressed: () => Get.toNamed(AppRoutes.childCreate),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add child'),
                  onPressed: () => AddChildDialog.show(
                    context,
                    onAdd: ({
                      required String name,
                      String? ageBracket,
                      String? avatar,
                    }) async {
                      final result = await controller.addChild(
                        name: name,
                        ageBracket: ageBracket,
                        avatar: avatar,
                      );
                      return result.isOk;
                    },
                  ),
                ),
              ],
            ),
            onTap: controller.goToChild,
          ),
          const SizedBox(height: HavenSpacing.md),
          PeopleCard(
            title: 'Parents',
            people: bundle.parents,
            emptyLine: 'This family has no other parent.',
            trailing: TextButton.icon(
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Invite'),
              onPressed: () => Get.toNamed(AppRoutes.familyInvite),
            ),
          ),
          const SizedBox(height: HavenSpacing.md),
          const FamilyGapsCard(),
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
