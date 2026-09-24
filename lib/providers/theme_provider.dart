import 'package:flutter/material.dart';

import '../services/preferencias_service.dart';

/// Mantém em memória o [ThemeMode] escolhido pelo usuário (claro, escuro
/// ou "seguir o sistema") e o persiste entre sessões.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _modo = ThemeMode.system;

  ThemeMode get modo => _modo;

  Future<void> carregar() async {
    _modo = await PreferenciasService.obterTemaModo();
    notifyListeners();
  }

  Future<void> definirModo(ThemeMode modo) async {
    if (_modo == modo) return;
    _modo = modo;
    notifyListeners();
    await PreferenciasService.definirTemaModo(modo);
  }
}
