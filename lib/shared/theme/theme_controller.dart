import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../data/hive_boxes.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    final box = Hive.box<Map>(HiveBoxes.settings);
    final s = box.get('ui') ?? {};
    final theme = (s['themeMode'] ?? 'system') as String;

    _mode = _parse(theme);
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    final box = Hive.box<Map>(HiveBoxes.settings);
    final current = Map<String, dynamic>.from(box.get('ui') ?? {});
    current['themeMode'] = _toString(mode);
    await box.put('ui', current);
    notifyListeners();
  }

  ThemeMode _parse(String v) {
    switch (v) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _toString(ThemeMode m) {
    if (m == ThemeMode.light) return 'light';
    if (m == ThemeMode.dark) return 'dark';
    return 'system';
  }
}