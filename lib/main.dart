import 'package:flutter/material.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  final state = AppState(db);
  await state.init();

  runApp(CalcMoneyApp(state: state));
}
