import '../backend_endpoints.dart';

/// Constraint registry for the local tables — the shape of the captured schema,
/// expressed in the rules the real database enforces.
final class LocalForeignKey {
  const LocalForeignKey({
    required this.childTable,
    required this.column,
    required this.parentTable,
    this.parentColumn = 'id',
  });

  final String childTable;
  final String column;
  final String parentTable;
  final String parentColumn;
}

final class LocalTableRule {
  const LocalTableRule({
    this.uniqueColumn = 'id',
    this.uniqueComposites = const [],
  });

  final String? uniqueColumn;
  final List<List<String>> uniqueComposites;
}

final class LocalSchema {
  const LocalSchema({
    this.tableNames = TableName.all,
    this.rules = const {},
    this.foreignKeys = const [],
  });

  static const String familyIdColumn = 'family_id';
  static const String deviceIdColumn = 'device_id';
  static const String idColumn = 'id';
  static const String nameColumn = 'name';
  static const String dayColumn = 'day';
  static const String packageNameColumn = 'package_name';
  static const String zoneIdColumn = 'zone_id';

  final List<String> tableNames;
  final Map<String, LocalTableRule> rules;
  final List<LocalForeignKey> foreignKeys;

  bool isKnown(String table) => tableNames.contains(table);

  LocalTableRule ruleFor(String table) => rules[table] ?? const LocalTableRule();

  List<LocalForeignKey> keysOn(String table) =>
      foreignKeys.where((key) => key.childTable == table).toList();

  List<LocalForeignKey> referencesTo(String table) =>
      foreignKeys.where((key) => key.parentTable == table).toList();

  static const LocalSchema defaults = LocalSchema(
    rules: <String, LocalTableRule>{
      TableName.families: LocalTableRule(),
      TableName.profiles: LocalTableRule(),
      TableName.familyMembers: LocalTableRule(
        uniqueComposites: <List<String>>[
          <String>[familyIdColumn, 'user_id'],
        ],
      ),
      TableName.devices: LocalTableRule(),
      TableName.safeZones: LocalTableRule(
        uniqueComposites: <List<String>>[
          <String>[familyIdColumn, nameColumn],
        ],
      ),
      TableName.safeZoneStates: LocalTableRule(
        uniqueColumn: null,
        uniqueComposites: <List<String>>[
          <String>[zoneIdColumn, deviceIdColumn],
        ],
      ),
      TableName.devicePolicies: LocalTableRule(),
      TableName.pairingRequests: LocalTableRule(),
      TableName.safetyAlerts: LocalTableRule(),
      TableName.usageDaily: LocalTableRule(
        uniqueComposites: <List<String>>[
          <String>[deviceIdColumn, dayColumn, packageNameColumn],
        ],
      ),
      TableName.locationEvents: LocalTableRule(),
    },
    foreignKeys: <LocalForeignKey>[
      LocalForeignKey(
        childTable: TableName.devices,
        column: familyIdColumn,
        parentTable: TableName.families,
      ),
      LocalForeignKey(
        childTable: TableName.familyMembers,
        column: familyIdColumn,
        parentTable: TableName.families,
      ),
      LocalForeignKey(
        childTable: TableName.safeZones,
        column: familyIdColumn,
        parentTable: TableName.families,
      ),
      LocalForeignKey(
        childTable: TableName.devicePolicies,
        column: familyIdColumn,
        parentTable: TableName.families,
      ),
      LocalForeignKey(
        childTable: TableName.devicePolicies,
        column: deviceIdColumn,
        parentTable: TableName.devices,
      ),
      LocalForeignKey(
        childTable: TableName.pairingRequests,
        column: familyIdColumn,
        parentTable: TableName.families,
      ),
      LocalForeignKey(
        childTable: TableName.safetyAlerts,
        column: familyIdColumn,
        parentTable: TableName.families,
      ),
      LocalForeignKey(
        childTable: TableName.safetyAlerts,
        column: deviceIdColumn,
        parentTable: TableName.devices,
      ),
      LocalForeignKey(
        childTable: TableName.usageDaily,
        column: familyIdColumn,
        parentTable: TableName.families,
      ),
      LocalForeignKey(
        childTable: TableName.usageDaily,
        column: deviceIdColumn,
        parentTable: TableName.devices,
      ),
      LocalForeignKey(
        childTable: TableName.locationEvents,
        column: familyIdColumn,
        parentTable: TableName.families,
      ),
      LocalForeignKey(
        childTable: TableName.locationEvents,
        column: deviceIdColumn,
        parentTable: TableName.devices,
      ),
      LocalForeignKey(
        childTable: TableName.safeZoneStates,
        column: zoneIdColumn,
        parentTable: TableName.safeZones,
      ),
      LocalForeignKey(
        childTable: TableName.safeZoneStates,
        column: deviceIdColumn,
        parentTable: TableName.devices,
      ),
    ],
  );
}
