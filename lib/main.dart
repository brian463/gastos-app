import 'package:flutter/material.dart';

import 'app.dart';
import 'data/sheets_config.dart';
import 'shared/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Si falta config, mostramos un mensaje simple
  if (!sheetsConfigOk()) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Falta configuración de Sheets.\n'
              'Vuelve a compilar la web con --dart-define.',
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