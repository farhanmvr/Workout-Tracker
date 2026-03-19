import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() {
    var box = Hive.box('settings');
    bool isDark = box.get('isDark', defaultValue: true); // Default to dark for dramatic modern feel
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    var box = Hive.box('settings');
    await box.put('isDark', _themeMode == ThemeMode.dark);
    notifyListeners();
  }
}
