import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/moto_model.dart';
import '../services/calculos_service.dart';
import '../services/preferencias_service.dart';

/// Serviço responsável por inicializar e disparar notificações locais
/// (push locais) quando a troca de óleo de uma moto está próxima ou
/// vencida.
///
/// Não é um serviço de push remoto: as notificações são geradas e exibidas
/// pelo próprio dispositivo, sem depender de servidor. Isso é suficiente
/// para alertas baseados nos dados que já estão salvos localmente.
class NotificacoesService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _inicializado = false;

  /// Deve ser chamado uma vez, no início do app (main.dart), antes de
  /// qualquer chamada a [verificarEAlertar].
  static Future<void> inicializar() async {
    if (_inicializado) return;

    const configAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const configIOS = DarwinInitializationSettings();
    const configuracoes = InitializationSettings(android: configAndroid, iOS: configIOS);

    await _plugin.initialize(configuracoes);

    // Solicita permissão de notificações (necessário no Android 13+ e no iOS).
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _inicializado = true;
  }

  /// Verifica o status de troca de óleo de uma moto e, se estiver próxima
  /// ou vencida, dispara uma notificação local — mas apenas se esse mesmo
  /// alerta ainda não tiver sido notificado antes (evita spam a cada
  /// abertura do app).
  static Future<void> verificarEAlertar({
    required Moto moto,
    required ResultadoAlertaOleo? alerta,
  }) async {
    if (!_inicializado || alerta == null) return;
    if (alerta.status == StatusTrocaOleo.emDia) return;

    final notificacoesAtivadas = await PreferenciasService.obterNotificacoesAtivadas();
    if (!notificacoesAtivadas || moto.id == null) return;

    // Assinatura simples: moto + status + km restante arredondado ao
    // centena mais próxima, para não repetir a notificação a cada km rodado.
    final kmArredondado = (alerta.quilometragemRestante / 100).round() * 100;
    final assinatura = '${moto.id}_${alerta.status}_$kmArredondado';

    final ultimaAssinatura = await PreferenciasService.obterUltimoAlertaOleoNotificado(moto.id!);
    if (ultimaAssinatura == assinatura) return;

    final titulo = alerta.status == StatusTrocaOleo.vencida
        ? 'Troca de óleo vencida'
        : 'Troca de óleo próxima';

    final corpo = alerta.status == StatusTrocaOleo.vencida
        ? '${moto.nome}: a troca de óleo já passou do previsto (${alerta.quilometragemProximaTroca.toStringAsFixed(0)} km).'
        : '${moto.nome}: faltam ${alerta.quilometragemRestante.toStringAsFixed(0)} km para a próxima troca de óleo.';

    const detalhesAndroid = AndroidNotificationDetails(
      'alerta_troca_oleo',
      'Alertas de troca de óleo',
      channelDescription: 'Avisos quando a troca de óleo está próxima ou vencida.',
      importance: Importance.high,
      priority: Priority.high,
    );
    const detalhesIOS = DarwinNotificationDetails();
    const detalhes = NotificationDetails(android: detalhesAndroid, iOS: detalhesIOS);

    await _plugin.show(moto.id!, titulo, corpo, detalhes);
    await PreferenciasService.definirUltimoAlertaOleoNotificado(moto.id!, assinatura);
  }
}
