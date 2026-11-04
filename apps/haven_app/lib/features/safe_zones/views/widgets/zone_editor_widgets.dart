import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_core/haven_core.dart' show BlockedFailure, HavenFailure;

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/zone_editor_controller.dart';

/// One field's refusal, read live so a parent is told before they press save.
///
/// The column name is the database's, because that is the name a refusal from
/// the write lane would carry too — the parent sees the same word either way.
class ZoneFieldError extends GetView<SafeZoneEditorController> {
  const ZoneFieldError(this.column, {super.key});

  final String column;

  @override
  Widget build(BuildContext context) => Obx(() {
    final String? error = controller.errors[column];
    if (error == null) return const SizedBox(height: HavenSpacing.sm);
    return Padding(
      padding: const EdgeInsets.only(
        top: HavenSpacing.xs,
        bottom: HavenSpacing.sm,
      ),
      child: Text(
        error,
        style: HavenText.caption.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  });
}

/// The outcome of a write that was attempted, shown under the button that sent
/// it. Nothing means the write has not been tried, or it succeeded and the
/// screen closed.
class ZoneWriteResult extends StatelessWidget {
  const ZoneWriteResult({super.key, required this.failure});

  final HavenFailure? failure;

  @override
  Widget build(BuildContext context) => failure == null
      ? const SizedBox(height: HavenSpacing.sm)
      : Padding(
          padding: const EdgeInsets.only(top: HavenSpacing.sm),
          child: failure is BlockedFailure
              ? BlockedNotice.fromFailure(failure! as BlockedFailure)
              : Text(failure!.message, style: HavenText.body),
        );
}
