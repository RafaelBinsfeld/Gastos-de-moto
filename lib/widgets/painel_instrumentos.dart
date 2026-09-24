import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/moto_model.dart';
import '../services/calculos_service.dart';
import '../theme/app_theme.dart';
import 'moto_avatar.dart';

/// Painel de instrumentos da Home: o elemento visual principal do app,
/// desenhado para lembrar o painel real de uma motocicleta — sempre em
/// fundo escuro (como um mostrador retroiluminado), com os números de
/// quilometragem e consumo em destaque e um medidor semicircular
/// mostrando o quão perto a moto está da próxima troca de óleo.
class PainelInstrumentos extends StatelessWidget {
  final Moto moto;
  final double quilometragemAtual;
  final double consumoMedio;
  final ResultadoAlertaOleo? alertaOleo;

  const PainelInstrumentos({
    super.key,
    required this.moto,
    required this.quilometragemAtual,
    required this.consumoMedio,
    required this.alertaOleo,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: CoresApp.grafite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MotoAvatar(moto: moto, raio: 16, corFundo: Colors.white.withOpacity(0.08)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  moto.nome.toUpperCase(),
                  style: textTheme.labelMedium?.copyWith(
                    color: Colors.white.withOpacity(0.65),
                    letterSpacing: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _buildLeitura(context, 'KM ATUAL', quilometragemAtual.toStringAsFixed(0), CoresApp.ambarPainel)),
              Container(width: 1, height: 44, color: Colors.white.withOpacity(0.1)),
              Expanded(
                child: _buildLeitura(
                  context,
                  'CONSUMO',
                  consumoMedio > 0 ? consumoMedio.toStringAsFixed(1) : '—',
                  const Color(0xFF7FA3B3),
                  sufixo: consumoMedio > 0 ? ' km/l' : '',
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _buildMedidorOleo(context),
        ],
      ),
    );
  }

  Widget _buildLeitura(BuildContext context, String rotulo, String valor, Color cor, {String sufixo = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white.withOpacity(0.5),
                letterSpacing: 1,
              ),
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: valor,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(color: cor, fontSize: 34),
              ),
              TextSpan(
                text: sufixo,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white.withOpacity(0.5)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedidorOleo(BuildContext context) {
    final alerta = alertaOleo;

    if (alerta == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white.withOpacity(0.5), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Registre uma troca de óleo para habilitar o alerta.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.6)),
              ),
            ),
          ],
        ),
      );
    }

    final Color corStatus;
    final String textoStatus;
    switch (alerta.status) {
      case StatusTrocaOleo.vencida:
        corStatus = const Color(0xFFE2695A);
        textoStatus = 'TROCA VENCIDA';
        break;
      case StatusTrocaOleo.proxima:
        corStatus = CoresApp.ambarPainel;
        textoStatus = 'TROCA PRÓXIMA';
        break;
      case StatusTrocaOleo.emDia:
        corStatus = const Color(0xFF6FAE87);
        textoStatus = 'EM DIA';
        break;
    }

    final progresso = _calcularProgresso(alerta);

    return Row(
      children: [
        SizedBox(
          width: 84,
          height: 46,
          child: CustomPaint(
            painter: _MedidorArcoPainter(
              progresso: progresso,
              corTrilha: Colors.white.withOpacity(0.12),
              corProgresso: corStatus,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                textoStatus,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: corStatus, letterSpacing: 0.8),
              ),
              const SizedBox(height: 2),
              Text(
                alerta.status == StatusTrocaOleo.vencida
                    ? 'passou ${(-alerta.quilometragemRestante).toStringAsFixed(0)} km do previsto'
                    : 'faltam ${alerta.quilometragemRestante.toStringAsFixed(0)} km',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Proporção (0 a 1) do intervalo de troca já percorrida, usada para
  /// preencher o arco do medidor.
  double _calcularProgresso(ResultadoAlertaOleo alerta) {
    final intervalo = moto.intervaloTrocaOleo;
    if (intervalo <= 0) return 0;
    final progresso = (intervalo - alerta.quilometragemRestante) / intervalo;
    return progresso.clamp(0.0, 1.0);
  }
}

/// Desenha um medidor em arco semicircular (como o mostrador de
/// combustível ou temperatura de um painel de moto): uma trilha de fundo e
/// um arco colorido representando a proporção preenchida.
class _MedidorArcoPainter extends CustomPainter {
  final double progresso;
  final Color corTrilha;
  final Color corProgresso;

  _MedidorArcoPainter({required this.progresso, required this.corTrilha, required this.corProgresso});

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height);
    final raio = math.min(size.width / 2, size.height) - 6;
    final rect = Rect.fromCircle(center: centro, radius: raio);

    final trilha = Paint()
      ..color = corTrilha
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final progressoPaint = Paint()
      ..color = corProgresso
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi, math.pi, false, trilha);
    if (progresso > 0) {
      canvas.drawArc(rect, math.pi, math.pi * progresso, false, progressoPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MedidorArcoPainter oldDelegate) {
    return oldDelegate.progresso != progresso || oldDelegate.corProgresso != corProgresso;
  }
}
