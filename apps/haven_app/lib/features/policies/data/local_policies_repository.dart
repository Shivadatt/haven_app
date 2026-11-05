// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart' show asInt, asMap;

import '../../../core/storage/preferences_store.dart';
import '../../child_devices/bindings/child_devices_bindings.dart';
import '../../child_devices/data/devices_repository.dart';
import '../../family/data/family_scope.dart';
import 'policies_models.dart';
import 'policies_repository.dart';
import 'policy_config.dart';

/// Offline local policies: mutations are persisted into `TableName.devicePolicies`
/// and local preferences, fulfilling Refusal #10 locally.
final class LocalPoliciesRepository implements PoliciesRepository {
  LocalPoliciesRepository({
    required FamilyScopeReader Function() scope,
    required RowReader Function() rows,
    required RowWriter Function() writer,
    required PreferencesStore Function() prefs,
    required DevicesRepository Function() devices,
  }) : _scope = scope,
       _rows = rows,
       _writer = writer,
       _prefs = prefs,
       _base = HavenPoliciesRepository(
         scope: scope,
         rows: rows,
         devices: devices,
       );

  final FamilyScopeReader Function() _scope;
  final RowReader Function() _rows;
  final RowWriter Function() _writer;
  final PreferencesStore Function() _prefs;
  final HavenPoliciesRepository _base;

  factory LocalPoliciesRepository.live() {
    final reader = FamilyScopeReader(
      auth: () => HavenBackend.auth,
      rows: () => HavenBackend.rows,
    );
    return LocalPoliciesRepository(
      scope: () => reader,
      rows: () => HavenBackend.rows,
      writer: () => HavenBackend.writer,
      prefs: () => Get.find<PreferencesStore>(),
      devices: ChildDevicesDependencies.ensureRepository,
    );
  }

  @override
  bool get canConfigure => true;

  @override
  Future<Result<PolicyBoard?>> load({String? deviceId}) =>
      _base.load(deviceId: deviceId);

  @override
  Future<Result<PolicyConfig>> loadConfig({String? deviceId}) async {
    final scope = await _scope().resolve();
    final mine = scope.valueOrNull;
    if (mine == null) return Ok<PolicyConfig>(PolicyConfig.defaults());

    final filter = <String, Object?>{
      'family_id': mine.familyId,
      if (deviceId != null && deviceId.isNotEmpty) 'device_id': deviceId,
    };

    final rowsRes = await _rows().rows(
      TableName.devicePolicies,
      eq: filter,
      orderDesc: 'created_at',
      limit: 1,
    );

    final rows = rowsRes.valueOrNull;
    if (rows != null && rows.isNotEmpty) {
      final rawPolicy = asMap(rows.first['policy']);
      if (rawPolicy.isNotEmpty) {
        return Ok<PolicyConfig>(PolicyConfig.fromJson(rawPolicy));
      }
    }

    final cached = await _prefs().read(PreferenceKey.policyConfig);
    if (cached != null && cached.isNotEmpty) {
      try {
        final decoded = asMap(jsonDecode(cached));
        return Ok<PolicyConfig>(PolicyConfig.fromJson(decoded));
      } catch (_) {}
    }

    return Ok<PolicyConfig>(PolicyConfig.defaults());
  }

  @override
  Future<Result<void>> saveConfig(
    PolicyConfig config, {
    String? deviceId,
  }) async {
    final validationError = config.validate();
    if (validationError != null) {
      return Err<void>(ValidationFailure(validationError, field: 'policy'));
    }

    final scope = await _scope().resolve();
    final mine = scope.valueOrNull;
    if (mine == null) return Err<void>(scope.failureOrNull!);

    final targetDeviceId = await _resolveDeviceId(mine.familyId, deviceId);
    if (targetDeviceId == null) {
      return const Err<void>(
        ValidationFailure('No device available for policy assignment.', field: 'device_id'),
      );
    }

    final existing = await _rows().rows(
      TableName.devicePolicies,
      eq: {'family_id': mine.familyId, 'device_id': targetDeviceId},
      orderDesc: 'version',
      limit: 1,
    );

    int version = 1;
    if (existing.isOk && existing.valueOrNull!.isNotEmpty) {
      final v = asInt(existing.valueOrNull!.first['version']);
      if (v != null) version = v + 1;
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final row = <String, Object?>{
      'id': LocalIds.create(),
      'family_id': mine.familyId,
      'device_id': targetDeviceId,
      'version': version,
      'policy': config.toJson(),
      'created_at': now,
      'created_by': mine.session.userId,
      'enforcement_status': 'pending',
      'last_error': null,
    };

    final saved = await _writer().insert(TableName.devicePolicies, row);
    if (saved.isOk) {
      await _prefs().write(
        PreferenceKey.policyConfig,
        jsonEncode(config.toJson()),
      );
    }
    return saved;
  }

  Future<String?> _resolveDeviceId(String familyId, String? deviceId) async {
    if (deviceId != null && deviceId.isNotEmpty) return deviceId;

    final devRows = await _rows().rows(
      TableName.devices,
      eq: {'family_id': familyId},
      limit: 1,
    );
    if (devRows.isOk && devRows.valueOrNull!.isNotEmpty) {
      return devRows.valueOrNull!.first['id'] as String?;
    }

    final newId = LocalIds.create();
    final created = await _writer().insert(TableName.devices, <String, Object?>{
      'id': newId,
      'family_id': familyId,
      'child_user_id': '',
      'installation_id': 'dev-',
      'display_name': 'Child Device',
      'platform': 'android',
      'enforcement_mode': 'block',
      'policy_version': 1,
      'status': 'active',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    return created.isOk ? newId : null;
  }
}
