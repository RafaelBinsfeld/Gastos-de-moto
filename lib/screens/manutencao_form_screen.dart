import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../models/manutencao_model.dart';

const List<String> kTiposServico = [
  'Troca de Óleo',
  'Filtro de Ar',
  'Kit Relação',
  'Pastilhas de Freio',
  'Pneus',
  'Vela de Ignição',
  'Outro',
];

class ManutencaoFormScreen extends StatefulWidget {
  /// Moto à qual a nova manutenção pertencerá (ignorado em modo de edição,
  /// onde a moto original do registro é preservada).
  final int motoId;

  /// Quando informado, o formulário abre em modo de edição, pré-preenchido
  /// com os dados desta manutenção.
  final Manutencao? manutencaoParaEditar;

  const ManutencaoFormScreen({
    super.key,
    required this.motoId,
    this.manutencaoParaEditar,
  });

  @override
  State<ManutencaoFormScreen> createState() => _ManutencaoFormScreenState();
}

class _ManutencaoFormScreenState extends State<ManutencaoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _formatoData = DateFormat('dd/MM/yyyy');

  late DateTime _data;
  late String _tipoServico;
  late final TextEditingController _tipoServicoOutroController;
  late final TextEditingController _quilometragemController;
  late final TextEditingController _valorPecaController;
  late final TextEditingController _valorMaoDeObraController;
  late final TextEditingController _observacaoController;

  bool _salvando = false;

  bool get _editando => widget.manutencaoParaEditar != null;

  @override
  void initState() {
    super.initState();
    final item = widget.manutencaoParaEditar;

    _data = item?.data ?? DateTime.now();

    final tipoConhecido = item != null && kTiposServico.contains(item.tipoServico);
    _tipoServico = item == null
        ? kTiposServico.first
        : (tipoConhecido ? item.tipoServico : 'Outro');

    _tipoServicoOutroController = TextEditingController(
      text: (item != null && !tipoConhecido) ? item.tipoServico : '',
    );
    _quilometragemController = TextEditingController(
      text: item != null ? item.quilometragem.toStringAsFixed(0) : '',
    );
    _valorPecaController = TextEditingController(
      text: item != null ? item.valorPeca.toStringAsFixed(2) : '',
    );
    _valorMaoDeObraController = TextEditingController(
      text: item != null ? item.valorMaoDeObra.toStringAsFixed(2) : '',
    );
    _observacaoController = TextEditingController(text: item?.observacao ?? '');
  }

  @override
  void dispose() {
    _tipoServicoOutroController.dispose();
    _quilometragemController.dispose();
    _valorPecaController.dispose();
    _valorMaoDeObraController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selecionada != null) {
      setState(() => _data = selecionada);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    final tipoServicoFinal =
        _tipoServico == 'Outro' ? _tipoServicoOutroController.text.trim() : _tipoServico;

    final manutencao = Manutencao(
      id: widget.manutencaoParaEditar?.id,
      motoId: widget.manutencaoParaEditar?.motoId ?? widget.motoId,
      data: _data,
      quilometragem: double.parse(_quilometragemController.text.replaceAll(',', '.')),
      tipoServico: tipoServicoFinal,
      valorPeca: double.tryParse(_valorPecaController.text.replaceAll(',', '.')) ?? 0,
      valorMaoDeObra: double.tryParse(_valorMaoDeObraController.text.replaceAll(',', '.')) ?? 0,
      observacao: _observacaoController.text.trim(),
    );

    if (_editando) {
      await DatabaseHelper.instance.atualizarManutencao(manutencao);
    } else {
      await DatabaseHelper.instance.inserirManutencao(manutencao);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar Manutenção' : 'Nova Manutenção')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data'),
              subtitle: Text(_formatoData.format(_data)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selecionarData,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _quilometragemController,
              decoration: const InputDecoration(
                labelText: 'Quilometragem atual (km)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) =>
                  (v == null || v.isEmpty || double.tryParse(v.replaceAll(',', '.')) == null)
                      ? 'Informe uma quilometragem válida'
                      : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _tipoServico,
              decoration: const InputDecoration(
                labelText: 'Tipo de serviço',
                border: OutlineInputBorder(),
              ),
              items: kTiposServico
                  .map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)))
                  .toList(),
              onChanged: (v) => setState(() => _tipoServico = v ?? kTiposServico.first),
            ),
            if (_tipoServico == 'Outro') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _tipoServicoOutroController,
                decoration: const InputDecoration(
                  labelText: 'Descreva o serviço',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (_tipoServico == 'Outro' && (v == null || v.trim().isEmpty))
                    ? 'Informe o tipo de serviço'
                    : null,
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _valorPecaController,
              decoration: const InputDecoration(
                labelText: 'Valor das peças (R\$)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valorMaoDeObraController,
              decoration: const InputDecoration(
                labelText: 'Valor da mão de obra (R\$)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _observacaoController,
              decoration: const InputDecoration(
                labelText: 'Observações',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _salvando ? null : _salvar,
              child: _salvando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
