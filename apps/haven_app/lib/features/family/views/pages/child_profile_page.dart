import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../../core/utils/haven_time.dart';
import '../../controllers/child_profile_controller.dart';
import '../../data/family_models.dart';
import '../dialogs/edit_child_dialog.dart';

/// One child: who they are in this family, and what a parent may change.
final class ChildProfilePage extends GetView<ChildProfileController> {
  const ChildProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Your child',
      body: HavenPageBody(
        child: Obx(
          () => StateView<FamilyPerson?>(
            isLoading: controller.isLoading.value,
            result: controller.person.value,
            onRetry: controller.load,
            empty: () => const _NotInFamily(),
            onData: (BuildContext context, FamilyPerson? person) =>
                _Content(person!),
          ),
        ),
      ),
    );
  }
}

class _Content extends GetView<ChildProfileController> {
  const _Content(this.person);

  final FamilyPerson person;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: person.name,
            subtitle: person.hasProfile
                ? 'In the family since '
                      '${havenDay(person.member.createdAt) ?? 'an unknown date'}'
                : 'This account has no name on file yet.',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (person.avatar != null) ...[
                  Text(person.avatar!, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: HavenSpacing.xs),
                ],
                StatusChip(
                  label: person.ageBracket != null
                      ? 'Ages ${person.ageBracket}'
                      : 'Child',
                  tone: StatusTone.neutral,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Haven knows this person as a child in your family.',
                  style: HavenText.body,
                ),
                const SizedBox(height: HavenSpacing.md),
                HavenButton(
                  label: 'Edit profile',
                  primary: false,
                  onPressed: () => EditChildDialog.show(
                    context,
                    initialName: person.name,
                    initialAgeBracket: person.ageBracket,
                    initialAvatar: person.avatar,
                    onSave: ({
                      required String name,
                      String? ageBracket,
                      String? avatar,
                    }) => controller.updateProfile(
                      name: name,
                      ageBracket: ageBracket,
                      avatar: avatar,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: HavenSpacing.md),
          _DeviceGap(),
          const SizedBox(height: HavenSpacing.md),
          _RemovalCard(person.name),
        ],
      ),
    );
  }
}

class _RemovalCard extends GetView<ChildProfileController> {
  const _RemovalCard(this.name);

  final String name;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Removing $name',
    subtitle: 'Taking a child out of the family stops their reporting.',
    child: Obx(() {
      if (controller.removalGap.value != null) {
        return BlockedNotice.fromFailure(controller.removalGap.value!);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unlinking $name removes their access and clears device assignments.',
            style: HavenText.body,
          ),
          const SizedBox(height: HavenSpacing.md),
          HavenButton(
            label: 'Remove $name from family',
            primary: false,
            busy: controller.isRemoving.value,
            onPressed: () async {
              final bool confirmed = await ConfirmSheet.confirm(
                context,
                title: 'Remove $name?',
                body:
                    'Taking $name out of the family stops all reporting and '
                    'unlinks their devices from Haven.',
                confirmLabel: 'Remove child',
                destructive: true,
              );
              if (confirmed) {
                await controller.removeChild();
              }
            },
          ),
        ],
      );
    }),
  );
}

class _DeviceGap extends GetView<ChildProfileController> {
  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Devices',
    subtitle: 'What this build can and cannot tell you about their phone.',
    child: Obx(
      () => controller.deviceGap.value == null
          ? const SizedBox.shrink()
          : BlockedNotice.fromFailure(controller.deviceGap.value!),
    ),
  );
}

/// Reached when the id in the route is no longer a child of this family — after
/// a removal, or from a stale link.
class _NotInFamily extends GetView<ChildProfileController> {
  const _NotInFamily();

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'This child is not in your family',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'They may have been removed, or the family has not loaded yet. Haven '
          'will not show you someone who is not yours to manage.',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.md),
        HavenButton(label: 'Back to family', onPressed: controller.goToFamily),
      ],
    ),
  );
}
