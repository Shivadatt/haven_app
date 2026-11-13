/// Haven offline storage engine, local database, tables, schema, constraints,
/// and backend contract interfaces.
///
/// This package has ZERO cloud SDK dependencies (no Firebase, no Supabase).
library;

export 'src/auth_contracts.dart';
export 'src/backend_endpoints.dart';
export 'src/backend_handle.dart';
export 'src/backend_status.dart';
export 'src/data_contracts.dart';
export 'src/demo_data_records.dart';
export 'src/demo_data_suite.dart';
export 'src/device_identity_impl.dart' show VaultDeviceIdentity;
export 'src/local_change_feed.dart';
export 'src/local_constraints.dart';
export 'src/local_document.dart';
export 'src/local_ids.dart';
export 'src/local_profile_store.dart';
export 'src/local_queries.dart';
export 'src/local_schema.dart';
export 'src/local_store.dart';
export 'src/local_tables.dart';
export 'src/local_user_auth.dart';
export 'src/offline_backends.dart';
export 'src/offline_haven_backend.dart';

