import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../models/abastecimento_model.dart';

class AbastecimentoFormScreen extends StatefulWidget {
  /// Moto à qual o novo abastecimento pertencerá (ignorado em modo de edição,
  /// onde a moto original do registro é preservada).
  final int motoId;

  /// Quando informado, o formulário abre em modo de edição, pré-preenchido
  /// com os dados deste abastecimento.
  final Abastecimento? abastecimentoParaEditar;

  const AbastecimentoFormScreen({
    super.key,
    required this.motoId,
    this.abastecimentoParaEditar,
  });

  @override
  State<AbastecimentoFormScreen> createState() => _AbastecimentoFormScreenState();
}

class _AbastecimentoFormScreenState extends State<AbastecimentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _formatoData = DateFormat('dd/MM/yyyy');

  late DateTime _data;
  late final TextEditingController _quilometragemController;
  late final TextEditingController _valorTotalController;
  late final TextEditingController _precoLitroController;

  double _litrosCalculados = 0;
  bool _salvando = false;

  bool get _editando => widget.abastecimentoParaEditar != null;

  @override
  void initState() {
    super.initState();
    final item = widget.abastecimentoParaEditar;

    _data = item?.data ?? DateTime.now();
    _quilometragemController = TextEditingController(
      text: item != null ? item.quilometragem.toStringAsFixed(0) : '',
    );
    _valorTotalController = TextEditingController(
      text: item != null ? item.valorTotal.toStringAsFixed(2) : '',
    );
    _precoLitroController = TextEditingController(
      text: item != null ? item.precoLitro.toStringAsFixed(2) : '',
    );
    _litrosCalculados = item?.litros ?? 0;

    _valorTotalController.addListener(_recalcularLitros);
    _precoLitroController.addListener(_recalcularLitros);
  }

  @override
  void dispose() {
    _quilometragemController.dispose();
    _valorTotalController.dispose();
    _precoLitroController.dispose();
    super.dispose();
  }

  void _recalcularLitros() {
    final valorTotal = double.tryParse(_valorTotalController.text.replaceAll(',', '.'));
    final precoLitro = double.tryParse(_precoLitroController.text.replaceAll(',', '.'));

    setState(() {
      if (valorTotal != null && precoLitro != null && precoLitro > 0) {
        _litrosCalculados = valorTotal / precoLitro;
      } else {
        _litrosCalculados = 0;
      }
    });
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
    if (_litrosCalculados <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe valor total e preço por litro válidos.')),
      );
      return;
    }

    setState(() => _salvando = true);

    final abastecimento = Abastecimento(
      id: widget.abastecimentoParaEditar?.id,
      motoId: widget.abastecimentoParaEditar?.motoId ?? widget.motoId,
      data: _data,
      quilometragem: double.parse(_quilometragemController.text.replaceAll(',', '.')),
      valorTotal: double.parse(_valorTotalController.text.replaceAll(',', '.')),
      precoLitro: double.parse(_precoLitroController.text.replaceAll(',', '.')),
      litros: _litrosCalculados,
    );

    if (_editando) {
      await DatabaseHelper.instance.atualizarAbastecimento(abastecimento);
    } else {
      await DatabaseHelper.instance.inserirAbastecimento(abastecimento);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar Abastecimento' : 'Novo Abastecimento')),
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
            TextFormField(
              controller: _valorTotalController,
              decoration: const InputDecoration(
                labelText: 'Valor total pago (R\$)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) =>
                  (v == null || v.isEmpty || double.tryParse(v.replaceAll(',', '.')) == null)
                      ? 'Informe um valor válido'
                      : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _precoLitroController,
              decoration: const InputDecoration(
                labelText: 'Preço por litro (R\$)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) =>
                  (v == null || v.isEmpty || double.tryParse(v.replaceAll(',', '.')) == null)
                      ? 'Informe um valor válido'
                      : null,
            ),
            const SizedBox(height: 24),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Litros abastecidos (calculado)'),
                    Text(
                      '${_litrosCalculados.toStringAsFixed(2)} L',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
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
