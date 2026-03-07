import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    // ✅ Sin Hive: no crashea en GitHub Pages
    _mode = ThemeMode.system;
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
  }
}