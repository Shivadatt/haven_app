import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_models/haven_models.dart' show SafeZone;

import '../../../../app/theme/haven_spacing.dart';
import '../../controllers/zone_editor_controller.dart';
import '../../data/safe_zone_rules.dart';
import '../widgets/zone_editor_widgets.dart';

/// Changing one place the family already named.
///
/// There is no "new place" version of this screen: `safe_zones` has no INSERT
/// grant for a signed-in client, so a form that could only ever be refused would
/// be a lie about what the app can do.
final class SafeZoneEditorPage extends GetView<SafeZoneEditorController> {
  const SafeZoneEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Change this place',
      body: HavenPageBody(
        child: Obx(
          () => StateView<SafeZone>(
            isLoading: controller.isLoading.value,
            result: controller.zone.value,
            onRetry: controller.load,
            onData: (BuildContext context, SafeZone zone) => _Form(zone),
          ),
        ),
      ),
    );
  }
}

class _Form extends GetView<SafeZoneEditorController> {
  const _Form(this.read);

  /// The row as it was read, kept so the page can say what a change is against.
  final SafeZone read;

  static const TextInputType _number = TextInputType.numberWithOptions(
    decimal: true,
    signed: true,
  );

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'What this place is',
          subtitle: 'Named for this family since ${_day(read.createdAt)}.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HavenField(
                label: 'What to call it',
                controller: controller.name,
                maxLength: SafeZoneRules.nameMax,
                helper: 'A name the child would recognise, like School.',
              ),
              const ZoneFieldError('name'),
              HavenField(
                label: 'Latitude',
                controller: controller.lat,
                keyboardType: _number,
                helper: 'Between -90 and 90.',
              ),
              const ZoneFieldError('lat'),
              HavenField(
                label: 'Longitude',
                controller: controller.lng,
                keyboardType: _number,
                helper: 'Between -180 and 180.',
              ),
              const ZoneFieldError('lng'),
              HavenField(
                label: 'How wide, in metres',
                controller: controller.radiusM,
                keyboardType: _number,
                helper:
                    'Between ${SafeZoneRules.radiusMin.toInt()} and '
                    '${SafeZoneRules.radiusMax.toInt()} m.',
              ),
              const ZoneFieldError('radius_m'),
              Obx(
                () => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('In use'),
                  subtitle: const Text('A paused place is not evaluated.'),
                  value: controller.active.value,
                  onChanged: (bool next) => controller.active.value = next,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: HavenSpacing.md),
        Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HavenButton(
                label: 'Save the change',
                busy: controller.isSaving.value,
                onPressed: controller.canSave && controller.hasChanges
                    ? controller.save
                    : null,
              ),
              ZoneWriteResult(
                failure: controller.saveResult.value?.failureOrNull,
              ),
            ],
          ),
        ),
        const SizedBox(height: HavenSpacing.md),
        Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HavenButton(
                label: 'Remove this place',
                primary: false,
                onPressed: () => _remove(context),
              ),
              ZoneWriteResult(
                failure: controller.deleteResult.value?.failureOrNull,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Future<void> _remove(BuildContext context) async {
    final bool agreed = await ConfirmSheet.confirm(
      context,
      title: 'Remove this place?',
      body:
          'The name, the position and the width of ${read.name} go away. '
          'Devices already told about it keep their own copy until they next '
          'check in.',
      confirmLabel: 'Remove it',
      destructive: true,
    );
    if (!agreed) return;
    await controller.delete();
  }

  static String _day(DateTime createdAt) =>
      '${createdAt.day}/${createdAt.month}/${createdAt.year}';
}
