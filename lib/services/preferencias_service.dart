import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço responsável por ler e gravar as preferências do usuário,
/// persistidas localmente com [SharedPreferences].
///
/// Preferências específicas de cada motocicleta (como o intervalo de troca
/// de óleo e o avatar) ficam salvas na própria tabela `motos`, não aqui —
/// este serviço cuida apenas de preferências globais do aplicativo.
class PreferenciasService {
  static const String _chaveMotoSelecionadaId = 'moto_selecionada_id';
  static const String _chaveNotificacoesAtivadas = 'notificacoes_ativadas';
  static const String _chaveTemaModo = 'tema_modo';

  /// Retorna o id da última moto selecionada pelo usuário, ou null se
  /// nenhuma preferência foi salva ainda.
  static Future<int?> obterMotoSelecionadaId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_chaveMotoSelecionadaId);
  }

  static Future<void> definirMotoSelecionadaId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_chaveMotoSelecionadaId, id);
  }

  /// Indica se os alertas de troca de óleo devem gerar notificações locais.
  /// Ativado por padrão.
  static Future<bool> obterNotificacoesAtivadas() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_chaveNotificacoesAtivadas) ?? true;
  }

  static Future<void> definirNotificacoesAtivadas(bool ativadas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chaveNotificacoesAtivadas, ativadas);
  }

  /// Modo de tema escolhido pelo usuário (claro, escuro ou "sistema").
  /// "Sistema" (padrão) segue a preferência de aparência do dispositivo.
  static Future<ThemeMode> obterTemaModo() async {
    final prefs = await SharedPreferences.getInstance();
    final valor = prefs.getString(_chaveTemaModo);
    switch (valor) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static Future<void> definirTemaModo(ThemeMode modo) async {
    final prefs = await SharedPreferences.getInstance();
    final valor = switch (modo) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_chaveTemaModo, valor);
  }

  /// Guarda uma "assinatura" do último alerta de óleo notificado (moto +
  /// status + quilometragem restante arredondada), para evitar notificar o
  /// mesmo alerta repetidamente a cada abertura do app.
  static Future<String?> obterUltimoAlertaOleoNotificado(int motoId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('ultimo_alerta_oleo_moto_$motoId');
  }

  static Future<void> definirUltimoAlertaOleoNotificado(int motoId, String assinatura) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ultimo_alerta_oleo_moto_$motoId', assinatura);
  }
}
