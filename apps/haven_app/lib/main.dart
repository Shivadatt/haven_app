import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:haven_app/app/app.dart';
import 'package:haven_app/core/constants/haven_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final HavenConfig config = HavenConfig.fromDefines(
    String.fromEnvironment('HAVEN_SUPABASE_URL'),
    String.fromEnvironment('HAVEN_SUPABASE_ANON_KEY'),
    String.fromEnvironment('HAVEN_FIREBASE_PROJECT_ID'),
    String.fromEnvironment('HAVEN_FIREBASE_APP_ID'),
    String.fromEnvironment('HAVEN_FIREBASE_API_KEY'),
  );
  if (kDebugMode && config.missingDefines().isNotEmpty) {
    // Names only; never print the values.
    debugPrint('haven: missing defines ${config.missingDefines().join(', ')}');
  }
  runApp(HavenApp(config: config));
}
