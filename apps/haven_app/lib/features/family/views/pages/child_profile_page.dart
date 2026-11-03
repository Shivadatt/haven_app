import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../../core/utils/haven_time.dart';
import '../../controllers/child_profile_controller.dart';
import '../../data/family_models.dart';

/// One child: who they are in this family, and the one thing a parent may
/// change about that.
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
            trailing: const StatusChip(
              label: 'Child',
              tone: StatusTone.neutral,
            ),
            child: Text(
              'Haven knows this person as a child in your family. Their name '
              'and their role are set by the service when they are created; '
              'this screen cannot rewrite either.',
              style: HavenText.body,
            ),
          ),
          const SizedBox(height: HavenSpacing.md),
          _DeviceGap(),
          const SizedBox(height: HavenSpacing.md),
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (controller.message.value != null) ...[
                  Text(controller.message.value!, style: HavenText.body),
                  const SizedBox(height: HavenSpacing.sm),
                ],
                HavenButton(
                  label: 'Remove from this family',
                  primary: false,
                  expand: true,
                  busy: controller.busy.value,
                  onPressed: () => _askToRemove(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// §12: a destructive action is confirmed first, in the words that make the
  /// consequence clear — unlinking stops the reporting, and pairing again is the
  /// only way back.
  Future<void> _askToRemove(BuildContext context) async {
    final bool yes = await ConfirmSheet.confirm(
      context,
      title: 'Remove ${person.name} from this family?',
      body:
          'Their device stops reporting to Haven, and any rule you set for '
          'them stops applying. To bring them back you would pair their device '
          'again.',
      confirmLabel: 'Remove',
    );
    if (yes) controller.remove();
  }
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
