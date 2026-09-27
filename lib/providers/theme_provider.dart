import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _keyColor = 'selected_theme_color';
  static const String _keyMode = 'selected_theme_mode';

  Color _primaryColor = Colors.amber;
  ThemeMode _modo = ThemeMode.dark;

  Color get primaryColor => _primaryColor;
  ThemeMode get modo => _modo;

  List<Color> get availableColors => const [
        Colors.amber,
        Colors.blue,
        Colors.green,
        Colors.red,
        Colors.purple,
        Colors.orange,
        Colors.teal,
      ];

  ThemeProvider() {
    _carregarPreferencias();
  }

  Future<void> updateColor(Color color) async {
    _primaryColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyColor, color.toARGB32());
  }

  Future<void> definirModo(ThemeMode modo) async {
    _modo = modo;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMode, modo.index);
  }

  Future<void> _carregarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();

    final colorValue = prefs.getInt(_keyColor);
    if (colorValue != null) {
      _primaryColor = Color(colorValue);
    }

    final modeIndex = prefs.getInt(_keyMode);
    if (modeIndex != null && modeIndex < ThemeMode.values.length) {
      _modo = ThemeMode.values[modeIndex];
    } else {
      _modo = ThemeMode.dark;
    }

    notifyListeners();
  }
}