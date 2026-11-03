import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/constants/haven_config.dart';
import 'bindings/initial_bindings.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'theme/haven_theme.dart';

/// Root widget: one `GetMaterialApp`, named routes, one theme, one binding set.
final class HavenApp extends StatelessWidget {
  const HavenApp({required this.config, super.key});

  final HavenConfig config;

  @override
  Widget build(BuildContext context) {
    InitialBindings.register(config);
    return GetMaterialApp(
      title: 'Haven',
      debugShowCheckedModeBanner: false,
      theme: HavenTheme.light,
      darkTheme: HavenTheme.dark,
      themeMode: ThemeMode.system,
      initialBinding: InitialBindings(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      unknownRoute: AppPages.unknown,
    );
  }
}
