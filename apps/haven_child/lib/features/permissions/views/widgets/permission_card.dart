import 'package:flutter/material.dart';
import 'package:haven_core/haven_core.dart';

import '../../../../app/theme/child_spacing.dart';
import '../../../../app/theme/child_text.dart';
import '../../../../shared/components/status_chip.dart';
import '../../../../core/permissions/permission_status_source.dart';
import '../../../../core/permissions/unconfigured_permission_status_source.dart';
import '../../controllers/permissions_controller.dart';

/// One capability card (brief §4 E): status chip, the WHY copy the child
/// read during onboarding, "User action required: No", and the
/// settings-navigation action rendered DISABLED with its own explanation —
/// because this build has no supported implementation to invoke. The card
/// has no path to render granted/denied without a real `Ok` read.
final class PermissionCard extends StatelessWidget {
  const PermissionCard({required this.state, super.key});

  final PermissionCardState state;

  @override
  Widget build(BuildContext context) {
    final permission = state.permission;
    final Result<PermissionStatus> answer = state.status;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ChildSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  permission.icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: ChildSpacing.sm),
                Expanded(
                  child: Text(permission.label, style: ChildText.headline),
                ),
              ],
            ),
            const SizedBox(height: ChildSpacing.sm),
            _StatusLine(answer: answer),
            const SizedBox(height: ChildSpacing.md),
            Text(permission.why, style: ChildText.body),
            const SizedBox(height: ChildSpacing.sm),
            Text(
              'User action required: No',
              style: ChildText.label.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: ChildSpacing.md),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Open device settings'),
            ),
            const SizedBox(height: ChildSpacing.xs),
            const Text(
              UnconfiguredPermissionStatusSource.settingsActionNote,
              style: ChildText.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.answer});

  final Result<PermissionStatus> answer;

  @override
  Widget build(BuildContext context) {
    final PermissionStatus? status = answer.valueOrNull;
    if (status != null) {
      return ChildStatusChip(
        key: const ValueKey('permission-real-read'),
        label: status.granted ? 'Granted' : 'Not granted',
        tone: status.granted ? StatusTone.good : StatusTone.warning,
      );
    }
    return const ChildStatusChip(
      key: ValueKey('permission-unavailable'),
      label: UnconfiguredPermissionStatusSource.cardStatusLabel,
      tone: StatusTone.blocked,
    );
  }
}
