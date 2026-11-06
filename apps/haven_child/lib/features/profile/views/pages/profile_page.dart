import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../../../app/theme/child_spacing.dart';
import '../../../../app/theme/child_text.dart';
import '../../../../shared/components/child_scaffold.dart';
import '../../../../shared/components/info_row.dart';
import '../../../../shared/components/state_view.dart';
import '../../../../shared/components/status_chip.dart';
import '../../../../core/device/device_information.dart';
import '../../../../core/session/child_local_session.dart';
import '../../../onboarding/data/child_avatars.dart';
import '../../controllers/profile_controller.dart';

/// The child profile home (`/profile`): who this device belongs to, when
/// setup happened, and the honest status lines —
/// "Parent connection: Not connected" and "Nothing is monitored yet".
final class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChildScaffold(
      title: 'My profile',
      showBack: false,
      body: ChildPageBody(
        child: Obx(
          () => ChildStateView<Profile?>(
            isLoading: controller.isLoading.value,
            result: controller.result.value,
            emptyMessage: 'No profile exists on this device yet.',
            empty: () => _SetupPrompt(controller: controller),
            onData: (context, profile) => _ProfileBody(
              profile: profile!,
              setupComplete: controller.sessionMatches.value,
              controller: controller,
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupPrompt extends StatelessWidget {
  const _SetupPrompt({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: ChildSpacing.lg),
      Text(
        'Setup is not finished on this device.',
        style: ChildText.headline,
      ),
      const SizedBox(height: ChildSpacing.md),
      FilledButton(
        onPressed: controller.startSetup,
        child: const Text('Start setup'),
      ),
    ],
  );
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.profile,
    required this.setupComplete,
    required this.controller,
  });

  final Profile profile;
  final bool setupComplete;
  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    final avatar = ChildAvatars.resolve(profile.avatar);
    final created = profile.createdAt;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: ChildSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                avatar.icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: ChildSpacing.md),
              Expanded(
                child: Text(profile.displayName, style: ChildText.title),
              ),
            ],
          ),
          const SizedBox(height: ChildSpacing.md),
          if (!setupComplete)
            const ChildStatusChip(
              key: ValueKey('profile-setup-incomplete'),
              label: 'Setup not finished yet',
              tone: StatusTone.warning,
            ),
          const SizedBox(height: ChildSpacing.lg),
          ChildInfoRow(
            label: 'Age group',
            value: profile.ageBracket ?? DeviceFacts.unavailable,
          ),
          ChildInfoRow(
            label: 'On this device since',
            value: created == null
                ? DeviceFacts.unavailable
                : formatDate(created),
          ),
          const SizedBox(height: ChildSpacing.xs),
          const ChildStatusChip(
            key: ValueKey('profile-parent-connection'),
            label:
                '${ChildLocalSession.parentConnectionLabel}: '
                '${ChildLocalSession.parentConnectionStatus}',
            tone: StatusTone.neutral,
          ),
          const SizedBox(height: ChildSpacing.xs),
          const ChildStatusChip(
            key: ValueKey('profile-nothing-monitored'),
            label: 'Nothing is monitored yet',
            tone: StatusTone.neutral,
          ),
          const SizedBox(height: ChildSpacing.lg),
          Text('This device', style: ChildText.headline),
          const SizedBox(height: ChildSpacing.xs),
          OutlinedButton(
            onPressed: controller.openDevice,
            child: const Text('Device info'),
          ),
          const SizedBox(height: ChildSpacing.lg),
          Text('Capabilities', style: ChildText.headline),
          const SizedBox(height: ChildSpacing.xs),
          OutlinedButton(
            onPressed: controller.openPermissions,
            child: const Text('Permission dashboard'),
          ),
        ],
      ),
    );
  }
}
