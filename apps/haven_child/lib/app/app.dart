import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/constants/child_config.dart';
import 'bindings/child_initial_bindings.dart';
import 'routes/child_pages.dart';
import 'routes/child_routes.dart';
import 'theme/child_theme.dart';

/// Root widget of the child companion: one `GetMaterialApp`, named routes
/// only, the child-owned flat theme, and the initial bindings. The shape
/// mirrors `apps/haven_app/lib/app/app.dart` on purpose.
final class ChildApp extends StatelessWidget {
  const ChildApp({required this.config, super.key});

  final ChildConfig config;

  @override
  Widget build(BuildContext context) {
    ChildInitialBindings.register(config);
    return GetMaterialApp(
      title: ChildConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ChildTheme.light,
      darkTheme: ChildTheme.dark,
      themeMode: ThemeMode.system,
      initialBinding: ChildInitialBindings(),
      initialRoute: ChildRoutes.splash,
      getPages: ChildPages.pages,
      unknownRoute: ChildPages.unknown,
    );
  }
}
