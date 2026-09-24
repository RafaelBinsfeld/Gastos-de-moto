import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/moto_provider.dart';
import '../providers/theme_provider.dart';
import '../services/preferencias_service.dart';
import '../widgets/moto_avatar.dart';
import '../widgets/responsive_helpers.dart';
import 'motos_screen.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  bool _carregando = true;
  bool _notificacoesAtivadas = true;

  @override
  void initState() {
    super.initState();
    _carregarPreferencias();
  }

  Future<void> _carregarPreferencias() async {
    final ativadas = await PreferenciasService.obterNotificacoesAtivadas();
    setState(() {
      _notificacoesAtivadas = ativadas;
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MotoProvider>();
    final motoAtual = provider.motoAtual;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Motocicletas', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: MotoAvatar(moto: motoAtual, raio: 18),
                        title: Text(motoAtual?.nome ?? '—'),
                        subtitle: Text(
                          motoAtual != null
                              ? 'Troca de óleo a cada ${motoAtual.intervaloTrocaOleo.toStringAsFixed(0)} km'
                              : '',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.settings_outlined),
                        title: const Text('Gerenciar motocicletas'),
                        subtitle: const Text('Adicionar, editar ou trocar entre motos, ajustar o intervalo de troca de óleo de cada uma'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await abrirTelaResponsiva(context, const MotosScreen());
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Aparência', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tema'),
                        const SizedBox(height: 10),
                        SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text('Claro'),
                              icon: Icon(Icons.light_mode_outlined),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text('Escuro'),
                              icon: Icon(Icons.dark_mode_outlined),
                            ),
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text('Sistema'),
                              icon: Icon(Icons.brightness_auto_outlined),
                            ),
                          ],
                          selected: {context.watch<ThemeProvider>().modo},
                          onSelectionChanged: (selecionados) {
                            context.read<ThemeProvider>().definirModo(selecionados.first);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Notificações', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  child: SwitchListTile(
                    secondary: const Icon(Icons.notifications_active_outlined),
                    title: const Text('Alertar sobre troca de óleo'),
                    subtitle: const Text('Notifica quando a troca estiver próxima ou vencida'),
                    value: _notificacoesAtivadas,
                    onChanged: (valor) async {
                      setState(() => _notificacoesAtivadas = valor);
                      await PreferenciasService.definirNotificacoesAtivadas(valor);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Text('Sobre', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Minha Moto — Gastos e Manutenção'),
                    subtitle: Text('Dados armazenados localmente no dispositivo (SQLite).'),
                  ),
                ),
              ],
            ),
    );
  }
}
