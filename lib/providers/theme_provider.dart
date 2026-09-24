import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _keyColor = 'selected_theme_color';
  
  // Cor padrão inicial (Amarelo)
  Color _primaryColor = Colors.amber;

  Color get primaryColor => _primaryColor;

  // Lista de cores disponíveis para o usuário escolher
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
    _loadColor();
  }

  Future<void> updateColor(Color color) async {
    _primaryColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyColor, color.value);
  }

  Future<void> _loadColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_keyColor);
    if (colorValue != null) {
      _primaryColor = Color(colorValue);
      notifyListeners();
    }
  }
}