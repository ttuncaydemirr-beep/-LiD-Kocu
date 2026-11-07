// LiD Koçu — app.dart: MaterialApp (dört dil, RTL, açık/koyu tema).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/app_config.dart';
import 'state/app_controller.dart';
import 'ui/shell.dart';
import 'ui/theme.dart';

class LidKocuApp extends StatelessWidget {
  const LidKocuApp({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? _) => MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        locale: controller.locale,
        supportedLocales: <Locale>[for (final String l in AppConfig.languages) Locale(l)],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: controller.themeMode,
        home: Shell(c: controller),
      ),
    );
  }
}
