import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../models/abastecimento_model.dart';
import '../models/manutencao_model.dart';
import '../providers/moto_provider.dart';
import '../utils/filtro_periodo.dart';
import '../widgets/linha_registro.dart';
import '../widgets/moto_switcher.dart';
import '../widgets/responsive_helpers.dart';
import 'abastecimento_form_screen.dart';
import 'manutencao_form_screen.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _db = DatabaseHelper.instance;

  FiltroPeriodo _periodo = FiltroPeriodo.todos;
  String? _tipoServicoFiltro; // null = todos os tipos

  int? _motoIdCarregado;
  Future<List<Abastecimento>>? _abastecimentosFuture;
  Future<List<Manutencao>>? _manutencoesFuture;
  Future<List<String>>? _tiposServicoFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _recarregar(int motoId) {
    setState(() {
      _abastecimentosFuture = _db.obterAbastecimentos(motoId: motoId, inicio: _periodo.inicio);
      _manutencoesFuture = _db.obterManutencoes(
        motoId: motoId,
        inicio: _periodo.inicio,
        tipoServico: _tipoServicoFiltro,
      );
      _tiposServicoFuture = _db.obterTiposServicoDistintos(motoId);
    });
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
      _abastecimentosFuture = _db.obterAbastecimentos(motoId: motoId, inicio: _periodo.inicio);
      _manutencoesFuture = _db.obterManutencoes(
        motoId: motoId,
        inicio: _periodo.inicio,
        tipoServico: _tipoServicoFiltro,
      );
      _tiposServicoFuture = _db.obterTiposServicoDistintos(motoId);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: const [SeletorMotoAction(), SizedBox(width: 8)],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Abastecimentos'),
            Tab(text: 'Manutenções'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFiltroPeriodo(motoId),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildListaAbastecimentos(motoId),
                _buildListaManutencoes(motoId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroPeriodo(int motoId) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          if (_tabController.index == 1) ...[
            const SizedBox(width: 8),
            FutureBuilder<List<String>>(
              future: _tiposServicoFuture,
              builder: (context, snapshot) {
                final tipos = snapshot.data ?? [];
                return DropdownButton<String?>(
                  value: _tipoServicoFiltro,
                  hint: const Text('Tipo de serviço'),
                  underline: const SizedBox.shrink(),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Todos os serviços')),
                    ...tipos.map((t) => DropdownMenuItem<String?>(value: t, child: Text(t))),
                  ],
                  onChanged: (valor) {
                    _tipoServicoFiltro = valor;
                    _recarregar(motoId);
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildListaAbastecimentos(int motoId) {
    return RefreshIndicator(
      onRefresh: () async => _recarregar(motoId),
      child: FutureBuilder<List<Abastecimento>>(
        future: _abastecimentosFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final itens = snapshot.data!;
          if (itens.isEmpty) {
            return ListView(
              children: const [
                EstadoVazioRegistro(
                  icone: Icons.local_gas_station_outlined,
                  mensagem: 'Nenhum abastecimento encontrado para este filtro.',
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: itens.length,
            itemBuilder: (context, index) {
              final a = itens[index];
              return LinhaAbastecimento(
                abastecimento: a,
                onTap: () async {
                  await abrirTelaResponsiva(
                    context,
                    AbastecimentoFormScreen(motoId: motoId, abastecimentoParaEditar: a),
                  );
                  _recarregar(motoId);
                },
                onExcluido: () async {
                  await _db.deletarAbastecimento(a.id!);
                  _recarregar(motoId);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildListaManutencoes(int motoId) {
    return RefreshIndicator(
      onRefresh: () async => _recarregar(motoId),
      child: FutureBuilder<List<Manutencao>>(
        future: _manutencoesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final itens = snapshot.data!;
          if (itens.isEmpty) {
            return ListView(
              children: const [
                EstadoVazioRegistro(
                  icone: Icons.build_outlined,
                  mensagem: 'Nenhuma manutenção encontrada para este filtro.',
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: itens.length,
            itemBuilder: (context, index) {
              final m = itens[index];
              return LinhaManutencao(
                manutencao: m,
                onTap: () async {
                  await abrirTelaResponsiva(
                    context,
                    ManutencaoFormScreen(motoId: motoId, manutencaoParaEditar: m),
                  );
                  _recarregar(motoId);
                },
                onExcluido: () async {
                  await _db.deletarManutencao(m.id!);
                  _recarregar(motoId);
                },
              );
            },
          );
        },
      ),
    );
  }
}
