import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'core/constants/child_config.dart';

/// Entry point. Reads the (minimal) dart-define set into [ChildConfig] and
/// hands it to the root widget, mirroring the parent app's bootstrap shape.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final ChildConfig config = ChildConfig.fromDefines(
    const String.fromEnvironment('HAVEN_CHILD_ENV'),
  );
  runApp(ChildApp(config: config));
}
