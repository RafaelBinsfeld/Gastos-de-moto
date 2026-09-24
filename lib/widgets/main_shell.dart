import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/moto_provider.dart';
import '../screens/configuracoes_screen.dart';
import '../screens/historico_screen.dart';
import '../screens/home_screen.dart';
import '../screens/relatorios_screen.dart';
import 'responsive_helpers.dart';

class _Destino {
  final IconData icone;
  final IconData iconeSelecionado;
  final String rotulo;

  const _Destino({required this.icone, required this.iconeSelecionado, required this.rotulo});
}

/// Widget raiz da navegação principal do app. Adapta o layout de acordo
/// com a largura da tela:
/// - Telas largas (desktop/tablet, >= 900px): NavigationRail lateral,
///   estendida com rótulos visíveis a partir de 1200px.
/// - Telas estreitas (mobile): barra de navegação inferior, como de
///   costume em apps móveis.
///
/// As quatro seções (Início, Histórico, Relatórios, Configurações) ficam
/// em um [IndexedStack], preservando o estado de cada uma ao trocar de aba.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _indiceAtual = 0;

  static const _destinos = [
    _Destino(icone: Icons.home_outlined, iconeSelecionado: Icons.home, rotulo: 'Início'),
    _Destino(icone: Icons.history_outlined, iconeSelecionado: Icons.history, rotulo: 'Histórico'),
    _Destino(icone: Icons.bar_chart_outlined, iconeSelecionado: Icons.bar_chart, rotulo: 'Relatórios'),
    _Destino(icone: Icons.settings_outlined, iconeSelecionado: Icons.settings, rotulo: 'Ajustes'),
  ];

  static const _telas = [
    HomeScreen(),
    HistoricoScreen(),
    RelatoriosScreen(),
    ConfiguracoesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MotoProvider>();
    if (provider.carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final corpo = IndexedStack(index: _indiceAtual, children: _telas);
    final ehDesktop = ehLayoutDesktop(context);

    if (ehDesktop) {
      final largura = MediaQuery.of(context).size.width;
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: largura >= kLarguraQuebraRailEstendida,
              minExtendedWidth: 200,
              selectedIndex: _indiceAtual,
              onDestinationSelected: (i) => setState(() => _indiceAtual = i),
              labelType: largura >= kLarguraQuebraRailEstendida
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.selected,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Icon(Icons.two_wheeler, size: 32),
              ),
              destinations: _destinos
                  .map((d) => NavigationRailDestination(
                        icon: Icon(d.icone),
                        selectedIcon: Icon(d.iconeSelecionado),
                        label: Text(d.rotulo),
                      ))
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: corpo),
          ],
        ),
      );
    }

    return Scaffold(
      body: corpo,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceAtual,
        onDestinationSelected: (i) => setState(() => _indiceAtual = i),
        destinations: _destinos
            .map((d) => NavigationDestination(
                  icon: Icon(d.icone),
                  selectedIcon: Icon(d.iconeSelecionado),
                  label: d.rotulo,
                ))
            .toList(),
      ),
    );
  }
}
