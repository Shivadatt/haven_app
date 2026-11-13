import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/child_spacing.dart';
import '../../../../app/theme/child_text.dart';
import '../../../../shared/components/status_chip.dart';
import '../../controllers/registration_controller.dart';
import '../../domain/registration_status.dart';

/// The label-only, route-free surface of the registration contract.
///
/// Stage 2 adds no page and no route, so this widget exists to be embedded
/// where an existing screen already shows device facts. It renders exactly two
/// honest things: the state's own `userLabel`, and the lane it came from
/// (`DEMO` / `BLOCKED`). It performs no action and can therefore never make a
/// child or a parent think a pairing happened.
final class RegistrationStatusLabel extends GetView<RegistrationController> {
  const RegistrationStatusLabel({this.showLane = true, super.key});

  final bool showLane;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final RegistrationStatus status = controller.currentStatus;
      final String? message = controller.message.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            spacing: ChildSpacing.xs,
            runSpacing: ChildSpacing.xs,
            children: <Widget>[
              ChildStatusChip(label: status.userLabel, tone: _tone(status)),
              if (showLane)
                ChildStatusChip(
                  label: 'LANE: ${controller.laneLabel}',
                  tone: controller.laneLabel == 'DEMO'
                      ? StatusTone.warning
                      : StatusTone.blocked,
                ),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: ChildSpacing.xs),
            Text(message, style: ChildText.caption),
          ],
        ],
      );
    });
  }

  /// `blocked` and `bad` stay distinct: a missing transport is not something
  /// the child did wrong, and a rejected code is not a system failure.
  static StatusTone _tone(RegistrationStatus status) => switch (status) {
    Unregistered() => StatusTone.neutral,
    DemoPending() => StatusTone.warning,
    Registered() => StatusTone.warning,
    Rejected() => StatusTone.bad,
    Revoked() => StatusTone.neutral,
  };
}
