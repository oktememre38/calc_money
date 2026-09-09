import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'screens/splash_page.dart';
import 'state/app_state.dart';
import 'theme.dart';

/// Uygulamanın kök widget'ı.
///
/// Not: [AppState], `main.dart` içinde ChangeNotifierProvider olarak bu
/// widget'ın üstüne sarılır; burada yalnızca watch ile okunur.
class CalcMoneyApp extends StatelessWidget {
  const CalcMoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final durum = context.watch<AppState>();
    return MaterialApp(
      title: 'CalcMoney',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: durum.temaModu,
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashPage(),
    );
  }
}
