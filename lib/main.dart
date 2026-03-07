import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/hive_boxes.dart';
import 'shared/theme/theme_controller.dart';
import 'data/sheets_config.dart';

if (!sheetsConfigOk()) {
  runApp(const MaterialApp(
    home: Scaffold(
      body: Center(
        child: Text(
          'Falta configuración SHEETS_URL / SHEETS_TOKEN.\nCompila con --dart-define.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  ));
  return;
}
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  await Hive.openBox<Map>(HiveBoxes.incomes);
  await Hive.openBox<Map>(HiveBoxes.expenses);
  await Hive.openBox<Map>(HiveBoxes.settings);

  // seed settings
  final settingsBox = Hive.box<Map>(HiveBoxes.settings);
  if (!settingsBox.containsKey('budget')) {
    settingsBox.put('budget', {'mode': 'percent', 'percent': 60.0, 'fixedAmount': 0.0});
  }
  if (!settingsBox.containsKey('alerts')) {
    settingsBox.put('alerts', {'enabled': true, 'threshold': 80.0});
  }
  if (!settingsBox.containsKey('ui')) {
    settingsBox.put('ui', {'themeMode': 'system'}); // system | light | dark
  }

  final themeController = ThemeController();
  await themeController.load();

  runApp(GastosApp(themeController: themeController));
}