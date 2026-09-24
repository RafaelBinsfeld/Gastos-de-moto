import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../models/abastecimento_model.dart';
import '../models/manutencao_model.dart';
import '../providers/moto_provider.dart';
import '../services/calculos_service.dart';
import '../services/notificacoes_service.dart';
import '../widgets/linha_registro.dart';
import '../widgets/moto_switcher.dart';
import '../widgets/painel_instrumentos.dart';
import '../widgets/responsive_helpers.dart';
import 'abastecimento_form_screen.dart';
import 'manutencao_form_screen.dart';

const String kTipoServicoTrocaOleo = 'Troca de Óleo';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseHelper.instance;

  Future<_ResumoHome>? _resumoFuture;
  int? _motoIdCarregado;

  void _recarregar(int motoId) {
    setState(() {
      _resumoFuture = _carregarResumo(motoId);
    });
  }

  Future<_ResumoHome> _carregarResumo(int motoId) async {
    final abastecimentos = await _db.obterAbastecimentos(motoId: motoId);
    final manutencoes = await _db.obterManutencoes(motoId: motoId);
    final ultimaQuilometragem = await _db.obterUltimaQuilometragem(motoId);

    // Consumo médio geral: média de consumo entre pares consecutivos de
    // abastecimentos (ordenados do mais recente para o mais antigo).
    double somaConsumo = 0;
    int qtdConsumo = 0;
    for (int i = 0; i < abastecimentos.length - 1; i++) {
      final atual = abastecimentos[i];
      final anterior = abastecimentos[i + 1];
      final consumo = CalculosService.calcularConsumo(
        quilometragemAtual: atual.quilometragem,
        quilometragemAnterior: anterior.quilometragem,
        litrosAtual: atual.litros,
      );
      if (consumo > 0) {
        somaConsumo += consumo;
        qtdConsumo++;
      }
    }
    final consumoMedio = qtdConsumo > 0 ? somaConsumo / qtdConsumo : 0.0;

    // Status da próxima troca de óleo, usando o intervalo configurado para esta moto.
    ResultadoAlertaOleo? alertaOleo;
    final ultimaTroca = await _db.obterUltimaManutencaoPorTipo(motoId, kTipoServicoTrocaOleo);
    if (ultimaTroca != null && mounted) {
      final moto = context.read<MotoProvider>().motoAtual;
      if (moto != null) {
        alertaOleo = CalculosService.verificarAlertaTrocaOleo(
          quilometragemUltimaTroca: ultimaTroca.quilometragem,
          intervaloRecomendado: moto.intervaloTrocaOleo,
          quilometragemAtual: ultimaQuilometragem,
        );
        await NotificacoesService.verificarEAlertar(moto: moto, alerta: alertaOleo);
      }
    }

    return _ResumoHome(
      ultimaQuilometragem: ultimaQuilometragem,
      consumoMedio: consumoMedio,
      alertaOleo: alertaOleo,
      abastecimentosRecentes: abastecimentos.take(5).toList(),
      manutencoesRecentes: manutencoes.take(5).toList(),
    );
  }

  Future<void> _editarAbastecimento(Abastecimento a) async {
    await abrirTelaResponsiva(
      context,
      AbastecimentoFormScreen(motoId: a.motoId, abastecimentoParaEditar: a),
    );
    if (_motoIdCarregado != null) _recarregar(_motoIdCarregado!);
  }

  Future<void> _editarManutencao(Manutencao m) async {
    await abrirTelaResponsiva(
      context,
      ManutencaoFormScreen(motoId: m.motoId, manutencaoParaEditar: m),
    );
    if (_motoIdCarregado != null) _recarregar(_motoIdCarregado!);
  }

  Future<void> _excluirAbastecimento(Abastecimento a) async {
    if (a.id == null) return;
    await _db.deletarAbastecimento(a.id!);
    if (_motoIdCarregado != null) _recarregar(_motoIdCarregado!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Abastecimento excluído.')),
      );
    }
  }

  Future<void> _excluirManutencao(Manutencao m) async {
    if (m.id == null) return;
    await _db.deletarManutencao(m.id!);
    if (_motoIdCarregado != null) _recarregar(_motoIdCarregado!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Manutenção excluída.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final motoAtual = context.watch<MotoProvider>().motoAtual;

    if (motoAtual?.id == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final motoId = motoAtual!.id!;
    if (motoId != _motoIdCarregado) {
      _motoIdCarregado = motoId;
      _resumoFuture = _carregarResumo(motoId);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Moto'),
        actions: const [SeletorMotoAction(), SizedBox(width: 8)],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _recarregar(motoId),
        child: FutureBuilder<_ResumoHome>(
          future: _resumoFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final resumo = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PainelInstrumentos(
                  moto: motoAtual,
                  quilometragemAtual: resumo.ultimaQuilometragem,
                  consumoMedio: resumo.consumoMedio,
                  alertaOleo: resumo.alertaOleo,
                ),
                const SizedBox(height: 24),
                Text('Últimos abastecimentos', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                if (resumo.abastecimentosRecentes.isEmpty)
                  const EstadoVazioRegistro(
                    icone: Icons.local_gas_station_outlined,
                    mensagem: 'Nenhum abastecimento registrado ainda.',
                  )
                else
                  ...resumo.abastecimentosRecentes.map((a) => LinhaAbastecimento(
                        abastecimento: a,
                        onTap: () => _editarAbastecimento(a),
                        onExcluido: () => _excluirAbastecimento(a),
                      )),
                const SizedBox(height: 14),
                Text('Últimas manutenções', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                if (resumo.manutencoesRecentes.isEmpty)
                  const EstadoVazioRegistro(
                    icone: Icons.build_outlined,
                    mensagem: 'Nenhuma manutenção registrada ainda.',
                  )
                else
                  ...resumo.manutencoesRecentes.map((m) => LinhaManutencao(
                        manutencao: m,
                        onTap: () => _editarManutencao(m),
                        onExcluido: () => _excluirManutencao(m),
                      )),
                const SizedBox(height: 80),
              ],
            );
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'fab_abastecimento',
            icon: const Icon(Icons.local_gas_station),
            label: const Text('Abastecimento'),
            onPressed: () async {
              await abrirTelaResponsiva(context, AbastecimentoFormScreen(motoId: motoId));
              _recarregar(motoId);
            },
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'fab_manutencao',
            icon: const Icon(Icons.build),
            label: const Text('Manutenção'),
            onPressed: () async {
              await abrirTelaResponsiva(context, ManutencaoFormScreen(motoId: motoId));
              _recarregar(motoId);
            },
          ),
        ],
      ),
    );
  }
}

class _ResumoHome {
  final double ultimaQuilometragem;
  final double consumoMedio;
  final ResultadoAlertaOleo? alertaOleo;
  final List<Abastecimento> abastecimentosRecentes;
  final List<Manutencao> manutencoesRecentes;

  _ResumoHome({
    required this.ultimaQuilometragem,
    required this.consumoMedio,
    required this.alertaOleo,
    required this.abastecimentosRecentes,
    required this.manutencoesRecentes,
  });
}
