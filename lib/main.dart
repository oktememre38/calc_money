import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  final state = AppState(db);
  await state.init();

  runApp(
    ChangeNotifierProvider.value(
      value: state,
      child: const CalcMoneyApp(),
    ),
  );
}
