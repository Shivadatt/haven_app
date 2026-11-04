import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_core/haven_core.dart' show HavenFailure;

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../../core/permissions/admin_and_media_states.dart';
import '../../../../core/permissions/area_reading.dart';
import '../../../../core/permissions/device_control_states.dart';
import '../../../../core/permissions/native_device_state.dart';
import '../../../../core/permissions/permission_and_monitoring_states.dart';
import '../../controllers/settings_controller.dart';

/// What the operating system under this app answers about itself, right now.
///
/// These are the only device statements in the app that come from a phone rather
/// than from a server, and each one is the phone's own word: allowed, not allowed,
/// or a refusal to say. A refusal is shown as a refusal, because the brief is
/// explicit that a restriction may not be claimed unless the OS confirms it — and an
/// installed app that is not a device owner is routinely told nothing.
final class DeviceStateCard extends GetView<SettingsController> {
  const DeviceStateCard({super.key});

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'What this phone answers',
    subtitle: 'Read from the operating system as this screen opened.',
    trailing: Obx(
      () => controller.deviceState.value == null
          ? const SizedBox.shrink()
          : StatusChip(
              label: 'Android ${controller.deviceState.value!.apiLevel}',
              tone: StatusTone.neutral,
            ),
    ),
    child: Obx(() {
      final DeviceStateReport? report = controller.deviceState.value;
      if (report == null) {
        return _Unreachable(controller.deviceStateFailure.value);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Area(
            area: report.permissions,
            label: 'permissions',
            say: _permissions,
          ),
          _Gap(),
          _Area(area: report.monitoring, label: 'monitoring', say: _monitoring),
          _Gap(),
          _Area(area: report.location, label: 'location', say: _location),
          _Gap(),
          _Area(area: report.deviceAdmin, label: 'device admin', say: _admin),
          _Gap(),
          _Area(area: report.communication, label: 'media', say: _media),
          const SizedBox(height: HavenSpacing.md),
          Text(
            'These answers are for this phone. A paired device answers for itself, '
            'and this build cannot read that from here.',
            style: HavenText.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }),
  );
}

/// The one shape every area has: the phone answered, or it gave a reason.
class _Area<T extends Object> extends StatelessWidget {
  const _Area({required this.area, required this.label, required this.say});

  final AreaReading<T> area;
  final String label;
  final String Function(T value) say;

  @override
  Widget build(BuildContext context) => Text(switch (area) {
    AnsweredArea<T>(:final value) => say(value),
    // The reason is the phone's own word (`no-answer`, `section-failed`), kept
    // verbatim rather than dressed up as a sentence about the device.
    RefusedArea<T>(:final reason) =>
      'This phone would not answer for $label ($reason).',
  }, style: HavenText.body);
}

class _Gap extends StatelessWidget {
  const _Gap();

  @override
  Widget build(BuildContext context) => const SizedBox(height: HavenSpacing.sm);
}

/// Shown when there is no lane to ask at all — a build with no native readers, not
/// a phone that said no.
class _Unreachable extends StatelessWidget {
  const _Unreachable(this.failure);

  final HavenFailure? failure;

  @override
  Widget build(BuildContext context) => Text(
    failure?.message ??
        'This build has no device-state lane to ask, so there is nothing to show '
            'here.',
    style: HavenText.body,
  );
}

String _permissions(PermissionStates states) =>
    'Notifications: ${states.answerFor('notifications').label}. '
    'Location while in use: ${states.answerFor('locationInUse').label}. '
    'Microphone: ${states.answerFor('microphone').label}. '
    'Camera: ${states.answerFor('camera').label}.';

String _monitoring(MonitoringStates states) =>
    '${states.usageLine} ${states.backgroundLine ?? 'The phone would not say what '
            'services this build declares.'}';

String _location(LocationStates states) =>
    'Providers switched on: '
    '${states.providersOn.isEmpty ? 'none' : states.providersOn.join(', ')}. '
    '${states.fixLine}';

String _admin(DeviceAdminStates states) =>
    '${states.standingLine} ${states.restrictionLine}';

String _media(CommunicationStates states) => states.mediaLine;
