import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart' show SafeZone;

import '../../../app/routes/app_routes.dart';
import '../data/safe_zone_rules.dart';
import '../data/zones_models.dart';
import '../data/zones_repository.dart';

/// Editing one named place.
///
/// The form is a copy of the row, and the only columns it can change are the five
/// the captured grant names (`docs/stage1/04-rls-matrix.md:33`): name, position,
/// radius, and whether the place is in use. Saving sends those and nothing else,
/// so a refusal points at a field the parent actually touched.
final class SafeZoneEditorController extends GetxController {
  SafeZoneEditorController({
    required this.zoneId,
    required SafeZonesRepository repository,
    void Function(String route, Object? arg)? replace,
    void Function()? close,
  }) : _repository = repository,
        _replace =
           replace ??
           ((String route, Object? arg) =>
               Get.offAllNamed(route, arguments: arg)),
       _close = close ?? Get.back;

  /// Empty when the route was opened without a zone id — which this build cannot
  /// fill in, because it cannot create a place.
  final String zoneId;

  final SafeZonesRepository _repository;
  final void Function(String route, Object? arg) _replace;
  final void Function() _close;

  final RxBool isLoading = true.obs;
  final Rx<Result<SafeZone>?> zone = Rx<Result<SafeZone>?>(null);

  final TextEditingController name = TextEditingController();
  final TextEditingController lat = TextEditingController();
  final TextEditingController lng = TextEditingController();
  final TextEditingController radiusM = TextEditingController();
  final RxBool active = true.obs;

  final RxBool isSaving = false.obs;
  final Rx<Result<void>?> saveResult = Rx<Result<void>?>(null);
  final Rx<Result<void>?> deleteResult = Rx<Result<void>?>(null);

  /// Bumped by every field so the page re-reads the validation without the
  /// widgets holding any logic of their own.
  final RxInt revision = 0.obs;

  @override
  void onInit() {
    super.onInit();
    for (final TextEditingController field in [name, lat, lng, radiusM]) {
      field.addListener(_touch);
    }
    load();
  }

  void _touch() => revision.value++;

  @override
  void onClose() {
    name.dispose();
    lat.dispose();
    lng.dispose();
    radiusM.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    final Result<SafeZone> read = await _repository.zone(zoneId);
    if (isClosed) return;
    zone.value = read;
    final SafeZone? found = read.valueOrNull;
    if (found != null) _seed(found);
    isLoading.value = false;
  }

  void _seed(SafeZone from) {
    name.text = from.name;
    lat.text = from.lat.toString();
    lng.text = from.lng.toString();
    radiusM.text = from.radiusM.toString();
    active.value = from.active;
  }

  bool get hasZone => zone.value?.valueOrNull != null;

  ZoneDraft get draft => ZoneDraft(
    name: name.text,
    lat: lat.text,
    lng: lng.text,
    radiusM: radiusM.text,
    active: active.value,
  );

  /// The schema's own bounds, read live so a parent is told before they save.
  Map<String, String?> get errors {
    revision
        .value; // the fields above are listened to, this makes it observable
    return draft.errors;
  }

  bool get isValid => SafeZoneRules.isClean(draft.errors);

  /// What the form holds that the row does not.
  bool get hasChanges {
    final SafeZone? read = zone.value?.valueOrNull;
    if (read == null) return false;
    revision.value; // typed text is only observable through the revision
    return name.text.trim() != read.name ||
        active.value != read.active ||
        _differs(lat.text, read.lat) ||
        _differs(lng.text, read.lng) ||
        _differs(radiusM.text, read.radiusM);
  }

  bool get canSave => hasZone && !isSaving.value && isValid;

  Future<void> save() async {
    if (!hasZone) return;
    isSaving.value = true;
    final Result<void> written = await _repository.save(
      zoneId: zoneId,
      draft: draft,
    );
    if (isClosed) return;
    saveResult.value = written;
    isSaving.value = false;
    if (written.isOk) _close();
  }

  /// The page asks first, so by the time this runs the parent has agreed. A
  /// screen that never read a place removes nothing — the id it would send is one
  /// nobody confirmed.
  Future<void> delete() async {
    if (!hasZone) return;
    final Result<void> removed = await _repository.remove(zoneId: zoneId);
    if (isClosed) return;
    deleteResult.value = removed;
    if (removed.isOk) _close();
  }

  void goToSetup() => _replace(AppRoutes.onboarding, null);

  static bool _differs(String value, double stored) {
    final double? parsed = double.tryParse(value.trim());
    return parsed == null || parsed != stored;
  }
}
