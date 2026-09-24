import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../providers/moto_provider.dart';
import '../services/calculos_service.dart';
import '../services/exportacao_service.dart';
import '../services/importacao_service.dart';
import '../theme/app_theme.dart';
import '../utils/filtro_periodo.dart';
import '../widgets/moto_switcher.dart';

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  final _db = DatabaseHelper.instance;
  final _formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _formatoMesAbrev = DateFormat('MMM/yy', 'pt_BR');

  FiltroPeriodo _periodo = FiltroPeriodo.ultimos6Meses;
  int? _motoIdCarregado;
  Future<_MetricasRelatorio>? _metricasFuture;
  bool _processando = false;

  void _recarregar(int motoId) {
    setState(() {
      _metricasFuture = _carregarMetricas(motoId);
    });
  }

  Future<_MetricasRelatorio> _carregarMetricas(int motoId) async {
    final inicioFiltro = _periodo.inicio;
    final fim = DateTime.now();

    // Ordenado do mais recente para o mais antigo (vindo do banco), já
    // respeitando o filtro de período selecionado.
    final abastecimentosDesc = await _db.obterAbastecimentos(motoId: motoId, inicio: inicioFiltro);
    // Para o gráfico de evolução, queremos ordem cronológica (mais antigo primeiro).
    final abastecimentosAsc = abastecimentosDesc.reversed.toList();

    double somaConsumo = 0;
    int qtdConsumo = 0;
    double somaCustoPorKm = 0;
    int qtdCustoPorKm = 0;
    final pontosConsumo = <FlSpot>[];

    for (int i = 0; i < abastecimentosDesc.length - 1; i++) {
      final atual = abastecimentosDesc[i];
      final anterior = abastecimentosDesc[i + 1];

      final consumo = CalculosService.calcularConsumo(
        quilometragemAtual: atual.quilometragem,
        quilometragemAnterior: anterior.quilometragem,
        litrosAtual: atual.litros,
      );
      if (consumo > 0) {
        somaConsumo += consumo;
        qtdConsumo++;
      }

      final custoPorKm = CalculosService.calcularCustoPorKm(
        valorTotal: atual.valorTotal,
        quilometragemAtual: atual.quilometragem,
        quilometragemAnterior: anterior.quilometragem,
      );
      if (custoPorKm > 0) {
        somaCustoPorKm += custoPorKm;
        qtdCustoPorKm++;
      }
    }

    for (int i = 1; i < abastecimentosAsc.length; i++) {
      final atual = abastecimentosAsc[i];
      final anterior = abastecimentosAsc[i - 1];
      final consumo = CalculosService.calcularConsumo(
        quilometragemAtual: atual.quilometragem,
        quilometragemAnterior: anterior.quilometragem,
        litrosAtual: atual.litros,
      );
      if (consumo > 0) {
        pontosConsumo.add(FlSpot(pontosConsumo.length.toDouble(), consumo));
      }
    }

    final consumoMedioGeral = qtdConsumo > 0 ? somaConsumo / qtdConsumo : 0.0;
    final custoMedioPorKm = qtdCustoPorKm > 0 ? somaCustoPorKm / qtdCustoPorKm : 0.0;

    final totalCombustivel = await _db.obterTotalGastoCombustivel(motoId, inicio: inicioFiltro, fim: fim);
    final totalManutencao = await _db.obterTotalGastoManutencao(motoId, inicio: inicioFiltro, fim: fim);
    final gastosMensais = await _db.obterGastosMensais(motoId, 6);

    return _MetricasRelatorio(
      consumoMedioGeral: consumoMedioGeral,
      totalCombustivel: totalCombustivel,
      totalManutencao: totalManutencao,
      custoMedioPorKm: custoMedioPorKm,
      pontosConsumo: pontosConsumo,
      gastosMensais: gastosMensais,
    );
  }

  Future<void> _executar(Future<void> Function() acao, {String? mensagemSucesso}) async {
    setState(() => _processando = true);
    try {
      await acao();
      if (mensagemSucesso != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagemSucesso)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ocorreu um erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _importar(int motoId, bool abastecimento) async {
    setState(() => _processando = true);
    try {
      final resultado = abastecimento
          ? await ImportacaoService.importarAbastecimentosCsv(motoId)
          : await ImportacaoService.importarManutencoesCsv(motoId);

      if (resultado == null) return; // usuário cancelou a seleção do arquivo

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            '${resultado.registrosImportados} registro(s) importado(s)'
            '${resultado.linhasComErro > 0 ? ', ${resultado.linhasComErro} linha(s) ignorada(s) por erro' : ''}.',
          ),
        ));
      }
      _recarregar(motoId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao importar: $e')));
      }
    } finally {
      if (mounted) setState(() => _processando = false);
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
      _metricasFuture = _carregarMetricas(motoId);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        actions: [
          const SeletorMotoAction(),
          PopupMenuButton<String>(
            icon: _processando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.ios_share),
            tooltip: 'Exportar ou importar CSV',
            enabled: !_processando,
            onSelected: (valor) {
              switch (valor) {
                case 'export_abastecimentos':
                  _executar(() => ExportacaoService.exportarAbastecimentosCsv(motoId));
                  break;
                case 'export_manutencoes':
                  _executar(() => ExportacaoService.exportarManutencoesCsv(motoId));
                  break;
                case 'import_abastecimentos':
                  _importar(motoId, true);
                  break;
                case 'import_manutencoes':
                  _importar(motoId, false);
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'export_abastecimentos', child: Text('Exportar abastecimentos (CSV)')),
              PopupMenuItem(value: 'export_manutencoes', child: Text('Exportar manutenções (CSV)')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'import_abastecimentos', child: Text('Importar abastecimentos (CSV)')),
              PopupMenuItem(value: 'import_manutencoes', child: Text('Importar manutenções (CSV)')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<_MetricasRelatorio>(
        future: _metricasFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final m = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildFiltroPeriodo(motoId),
              const SizedBox(height: 8),
              _buildCardMetrica(
                icone: Icons.speed,
                titulo: 'Consumo médio no período',
                valor: '${m.consumoMedioGeral.toStringAsFixed(2)} km/l',
              ),
              _buildCardMetrica(
                icone: Icons.local_gas_station,
                titulo: 'Gasto com combustível no período',
                valor: _formatoMoeda.format(m.totalCombustivel),
              ),
              _buildCardMetrica(
                icone: Icons.build,
                titulo: 'Gasto com manutenções e peças no período',
                valor: _formatoMoeda.format(m.totalManutencao),
              ),
              _buildCardMetrica(
                icone: Icons.attach_money,
                titulo: 'Custo médio por km rodado',
                valor: '${_formatoMoeda.format(m.custoMedioPorKm)} / km',
              ),
              const SizedBox(height: 24),
              Text('Evolução do consumo (km/l)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _buildGraficoConsumo(m.pontosConsumo),
              const SizedBox(height: 24),
              Text('Gastos por mês (últimos 6 meses)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _buildGraficoGastosMensais(m.gastosMensais),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegenda(CoresApp.ambarPainel, 'Combustível'),
                  const SizedBox(width: 16),
                  _buildLegenda(CoresApp.acoAsfalto, 'Manutenção'),
                ],
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFiltroPeriodo(int motoId) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filtro in FiltroPeriodo.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(filtro.rotulo),
                selected: _periodo == filtro,
                onSelected: (_) {
                  _periodo = filtro;
                  _recarregar(motoId);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardMetrica({required IconData icone, required String titulo, required String valor}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icone),
        title: Text(titulo),
        trailing: Text(
          valor,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildLegenda(Color cor, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: cor),
        const SizedBox(width: 6),
        Text(texto, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildGraficoConsumo(List<FlSpot> pontos) {
    if (pontos.length < 2) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('Registre ao menos 3 abastecimentos no período para ver a evolução do consumo.'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) => Text(
                      value.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: pontos,
                  isCurved: true,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGraficoGastosMensais(List<GastoMensal> gastos) {
    final temDados = gastos.any((g) => g.total > 0);
    if (!temDados) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('Nenhum gasto registrado nos últimos 6 meses.'),
          ),
        ),
      );
    }

    final maiorValor = gastos
        .map((g) => g.combustivel > g.manutencao ? g.combustivel : g.manutencao)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
        child: SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              maxY: maiorValor <= 0 ? 10 : maiorValor * 1.2,
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (value, meta) => Text(
                      value.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 9),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final indice = value.toInt();
                      if (indice < 0 || indice >= gastos.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _formatoMesAbrev.format(gastos[indice].mesReferencia),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (int i = 0; i < gastos.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(toY: gastos[i].combustivel, color: CoresApp.ambarPainel, width: 8),
                      BarChartRodData(toY: gastos[i].manutencao, color: CoresApp.acoAsfalto, width: 8),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricasRelatorio {
  final double consumoMedioGeral;
  final double totalCombustivel;
  final double totalManutencao;
  final double custoMedioPorKm;
  final List<FlSpot> pontosConsumo;
  final List<GastoMensal> gastosMensais;

  _MetricasRelatorio({
    required this.consumoMedioGeral,
    required this.totalCombustivel,
    required this.totalManutencao,
    required this.custoMedioPorKm,
    required this.pontosConsumo,
    required this.gastosMensais,
  });
}
