import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/child_spacing.dart';
import '../../../../app/theme/child_text.dart';
import '../../../../shared/components/child_scaffold.dart';
import '../../../../shared/components/info_row.dart';
import '../../../../core/device/device_fact_rows.dart';
import '../../controllers/device_info_controller.dart';

/// `/device` — this device's own information (brief §4 D). Every field is a
/// real pure-Dart read or the literal "Unavailable"; the two native-only
/// fields (model, manufacturer) say so rather than showing invented values,
/// and registration is the honest constant until Stage-2 pairing.
final class DevicePage extends GetView<DeviceInfoController> {
  const DevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = DeviceFactRows.build(controller.facts);
    return ChildScaffold(
      title: 'This device',
      body: ChildPageBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: ChildSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Device information', style: ChildText.title),
              const SizedBox(height: ChildSpacing.md),
              for (final row in rows)
                ChildInfoRow(label: row.label, value: row.value),
              const SizedBox(height: ChildSpacing.lg),
              const _HonestNote(
                title: 'Why some fields are unavailable',
                body: DeviceFactRows.stageOneNote,
              ),
              const SizedBox(height: ChildSpacing.md),
              const _HonestNote(
                title: 'About registration',
                body: DeviceFactRows.registrationNote,
              ),
              const SizedBox(height: ChildSpacing.md),
              const Text(
                'This screen has no buttons that pretend to work: there is '
                'nothing here to enable, retry, or grant yet.',
                style: ChildText.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HonestNote extends StatelessWidget {
  const _HonestNote({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: ChildText.headline),
      const SizedBox(height: ChildSpacing.xs),
      Text(body, style: ChildText.caption),
    ],
  );
}
