import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../controllers/family_controller.dart';

/// Card reporting unapproved membership changes in cloud mode.
final class FamilyGapsCard extends GetView<FamilyController> {
  const FamilyGapsCard({super.key});

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
