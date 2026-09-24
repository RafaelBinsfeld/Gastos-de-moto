import 'package:flutter/material.dart';

/// Largura mínima, em pixels lógicos, a partir da qual o app é tratado
/// como "desktop" (usa NavigationRail, diálogos centralizados etc.) em vez
/// do layout compacto de "mobile".
const double kLarguraQuebraDesktop = 900;

/// Largura mínima a partir da qual a NavigationRail é exibida estendida
/// (com rótulos visíveis ao lado dos ícones).
const double kLarguraQuebraRailEstendida = 1200;

bool ehLayoutDesktop(BuildContext context) {
  return MediaQuery.of(context).size.width >= kLarguraQuebraDesktop;
}

/// Abre uma tela de forma adaptada ao tamanho da janela:
/// - Em telas largas (desktop/tablet), abre como um diálogo centralizado
///   de largura fixa, para não esticar formulários por toda a tela.
/// - Em telas estreitas (mobile), empurra como uma rota de tela cheia,
///   como de costume.
Future<T?> abrirTelaResponsiva<T>(BuildContext context, Widget tela) {
  if (ehLayoutDesktop(context)) {
    return showDialog<T>(
      context: context,
      builder: (_) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
          child: tela,
        ),
      ),
    );
  }
  return Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => tela));
}
