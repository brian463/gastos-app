import 'package:flutter/material.dart';

import 'app.dart';
import 'data/sheets_config.dart';
import 'shared/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Validar configuración (debe ir dentro de main)
  if (!sheetsConfigOk()) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Falta configuración.\n\n'
              'SHEETS_URL: "$kSheetsUrl"\n'
              'SHEETS_TOKEN vacío?: ${kSheetsToken.isEmpty}\n'
              'SHEETS_USER: "$kSheetsUser"\n\n'
              'Compila con:\n'
              '--dart-define=SHEETS_URL=...\n'
              '--dart-define=SHEETS_TOKEN=...\n'
              '--dart-define=SHEETS_USER=...\n',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
    return;
  }

  final themeController = ThemeController();
  await themeController.load();

  runApp(GastosApp(themeController: themeController));
}