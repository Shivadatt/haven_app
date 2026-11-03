/// Haven backend clients.
///
/// The only layer allowed to touch `supabase_flutter`, `firebase_*` or the Edge
/// Function HTTP surface. Widgets and controllers depend on the contracts here,
/// never on an SDK type.
library;

export 'src/auth_contracts.dart';
export 'src/backend_endpoints.dart';
export 'src/backend_status.dart';
export 'src/data_contracts.dart';
