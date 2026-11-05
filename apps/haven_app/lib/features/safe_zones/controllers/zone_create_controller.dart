import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import '../data/safe_zone_rules.dart';
import '../data/zones_models.dart';
import '../data/zones_repository.dart';

/// Controller for creating a new safe zone.
///
/// Converts refusal #12 by writing the zone locally to the database.
final class SafeZoneCreateController extends GetxController {
  SafeZoneCreateController({
    required this.repository,
    void Function()? close,
  }) : _close = close ?? Get.back;

  final SafeZonesRepository repository;
  final void Function() _close;

  final TextEditingController name = TextEditingController();
  final TextEditingController lat = TextEditingController();
  final TextEditingController lng = TextEditingController();
  final RxDouble radiusM = 150.0.obs;
  final RxBool active = true.obs;

  final RxBool isSaving = false.obs;
  final Rx<Result<void>?> saveResult = Rx<Result<void>?>(null);
  final RxInt revision = 0.obs;

  @override
  void onInit() {
    super.onInit();
    for (final field in [name, lat, lng]) {
      field.addListener(_touch);
    }
  }

  void _touch() => revision.value++;

  @override
  void onClose() {
    name.dispose();
    lat.dispose();
    lng.dispose();
    super.onClose();
  }

  void setRadius(double value) {
    radiusM.value = value.clamp(
      SafeZoneRules.radiusMin,
      SafeZoneRules.radiusMax,
    );
    _touch();
  }

  void stepRadius(double delta) {
    setRadius(radiusM.value + delta);
  }

  ZoneDraft get draft => ZoneDraft(
    name: name.text,
    lat: lat.text,
    lng: lng.text,
    radiusM: radiusM.value.toStringAsFixed(0),
    active: active.value,
  );

  Map<String, String?> get errors {
    revision.value;
    return draft.errors;
  }

  bool get isValid {
    revision.value;
    return SafeZoneRules.isClean(draft.errors);
  }

  bool get canCreate => !isSaving.value && isValid;

  Future<void> createZone() async {
    if (!canCreate) return;
    isSaving.value = true;
    final Result<void> result = await repository.create(draft: draft);
    if (isClosed) return;
    saveResult.value = result;
    isSaving.value = false;
    if (result.isOk) _close();
  }
}
