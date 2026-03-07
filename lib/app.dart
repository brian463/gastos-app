import 'package:flutter/material.dart';
import 'features/home/home_page.dart';
import 'shared/theme/theme_controller.dart';
import 'shared/theme/theme_scope.dart';

class GastosApp extends StatelessWidget {
  final ThemeController themeController;
  const GastosApp({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Calculadora de gastos',
          debugShowCheckedModeBanner: false,
          themeMode: themeController.mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
            useMaterial3: true,
            brightness: Brightness.dark,
          ),

          // ✅ Aquí: ponemos el ThemeScope para que todas las pantallas accedan al controller
          home: ThemeScope(
            controller: themeController,
            child: const HomePage(),
          ),
        );
      },
    );
  }
}