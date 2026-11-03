import 'package:flutter/material.dart';
import 'package:haven_app/app/theme/haven_theme.dart';

/// Every shell widget test pumps through the real theme, because a token that
/// only exists in light mode is a bug the test should be able to see.
Widget widgetHost(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: HavenTheme.light,
      darkTheme: HavenTheme.dark,
      themeMode: brightness == Brightness.light
          ? ThemeMode.light
          : ThemeMode.dark,
      home: Scaffold(body: child),
    );
