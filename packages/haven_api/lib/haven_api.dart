/// Haven backend clients.
///
/// The only layer allowed to touch `supabase_flutter`, `firebase_*` or the Edge
/// Function HTTP surface. Widgets and controllers depend on the contracts here,
/// never on an SDK type.
library;

export 'src/auth_contracts.dart';
export 'src/backend_endpoints.dart';
export 'src/backend_status.dart';
export 'src/change_feed_impl.dart' show SupabaseChangeFeed;
export 'src/data_contracts.dart';
export 'src/device_identity_impl.dart' show VaultDeviceIdentity;
export 'src/edge_caller_impl.dart' show SupabaseEdgeCaller, dataFrom;
export 'src/failure_mapper.dart' show mapSupabaseError, mapPostgrest, mapAuth;
export 'src/haven_backend.dart';
export 'src/offline_backends.dart';
export 'src/offline/demo_data_suite.dart';
export 'src/offline/local_change_feed.dart';
export 'src/offline/local_constraints.dart';
export 'src/offline/local_document.dart';
export 'src/offline/local_ids.dart';
export 'src/offline/local_profile_store.dart';
export 'src/offline/local_queries.dart';
export 'src/offline/local_schema.dart';
export 'src/offline/local_store.dart';
export 'src/offline/local_tables.dart';
export 'src/offline/local_user_auth.dart';
export 'src/offline/offline_haven_backend.dart';
export 'src/push_transport_impl.dart' show FirebasePushTransport;
export 'src/supabase_data.dart' show SupabaseRowReader, SupabaseRpcCaller;
export 'src/supabase_write.dart' show SupabaseRowWriter;
export 'src/supabase_profile_store.dart' show SupabaseProfileStore;
export 'src/supabase_user_auth.dart' show SupabaseUserAuth;
