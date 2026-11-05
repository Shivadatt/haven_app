import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/child_create_controller.dart';
import '../../data/child_profile_constants.dart';

/// Standalone screen for adding a new child profile to the family.
final class ChildCreatePage extends GetView<ChildCreateController> {
  const ChildCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Add child',
      showBack: true,
      body: HavenPageBody(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
          children: [
            SectionCard(
              title: 'Child details',
              subtitle: 'Create a profile to assign devices and set rules.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(
                    () => HavenField(
                      label: 'Child name',
                      controller: controller.nameController,
                      helper: controller.nameError.value,
                      maxLength: ChildProfileConstants.maxNameLength,
                      enabled: !controller.busy.value,
                    ),
                  ),
                  const SizedBox(height: HavenSpacing.md),
                  Text('Age group', style: HavenText.title),
                  const SizedBox(height: HavenSpacing.xs),
                  _AgeBracketSelector(controller: controller),
                  const SizedBox(height: HavenSpacing.md),
                  Text('Choose avatar', style: HavenText.title),
                  const SizedBox(height: HavenSpacing.xs),
                  _AvatarSelector(controller: controller),
                  const SizedBox(height: HavenSpacing.md),
                  Obx(() {
                    final String? err = controller.formError.value;
                    if (err == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: HavenSpacing.sm),
                      child: Text(err, style: HavenText.body.copyWith(color: Colors.redAccent)),
                    );
                  }),
                  Obx(
                    () => HavenButton(
                      label: 'Create profile',
                      expand: true,
                      busy: controller.busy.value,
                      onPressed: controller.createChild,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgeBracketSelector extends StatelessWidget {
  const _AgeBracketSelector({required this.controller});
  final ChildCreateController controller;

  @override
  Widget build(BuildContext context) => Obx(
    () => Wrap(
      spacing: HavenSpacing.xs,
      children: [
        for (final String bracket in ChildProfileConstants.ageBrackets)
          ChoiceChip(
            label: Text('$bracket yrs'),
            selected: controller.selectedAgeBracket.value == bracket,
            onSelected: (bool selected) {
              if (selected) controller.selectedAgeBracket.value = bracket;
            },
          ),
      ],
    ),
  );
}

class _AvatarSelector extends StatelessWidget {
  const _AvatarSelector({required this.controller});
  final ChildCreateController controller;

  @override
  Widget build(BuildContext context) => Obx(
    () => Wrap(
      spacing: HavenSpacing.xs,
      children: [
        for (final String avatar in ChildProfileConstants.avatars)
          ChoiceChip(
            label: Text(avatar, style: const TextStyle(fontSize: 20)),
            selected: controller.selectedAvatar.value == avatar,
            onSelected: (bool selected) {
              if (selected) controller.selectedAvatar.value = avatar;
            },
          ),
      ],
    ),
  );
}
