import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../models/moto_model.dart';
import '../providers/moto_provider.dart';
import '../services/imagem_moto_service.dart';
import '../widgets/moto_avatar.dart';

class MotosScreen extends StatelessWidget {
  const MotosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MotoProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Motocicletas')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.motos.length,
        itemBuilder: (context, index) {
          final moto = provider.motos[index];
          final selecionada = moto.id == provider.motoAtual?.id;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            color: selecionada ? Theme.of(context).colorScheme.primary.withOpacity(0.12) : null,
            child: ListTile(
              leading: MotoAvatar(moto: moto, raio: 22),
              title: Text(moto.nome),
              subtitle: Text(
                '${moto.apelidoOuPlaca?.isNotEmpty == true ? '${moto.apelidoOuPlaca} • ' : ''}'
                'Troca de óleo a cada ${moto.intervaloTrocaOleo.toStringAsFixed(0)} km',
              ),
              onTap: () => provider.selecionar(moto),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Editar',
                    onPressed: () => _abrirFormulario(context, motoParaEditar: moto),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Excluir',
                    onPressed: provider.motos.length <= 1
                        ? null
                        : () => _confirmarExclusao(context, moto),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nova moto'),
        onPressed: () => _abrirFormulario(context),
      ),
    );
  }

  Future<void> _confirmarExclusao(BuildContext context, Moto moto) async {
    final provider = context.read<MotoProvider>();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir motocicleta?'),
        content: Text(
          'Todos os abastecimentos e manutenções de "${moto.nome}" serão '
          'excluídos permanentemente. Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmado == true && moto.id != null) {
      await ImagemMotoService.excluirSeExistir(moto.imagemPath);
      await DatabaseHelper.instance.deletarMoto(moto.id!);
      await provider.carregar();
    }
  }

  Future<void> _abrirFormulario(BuildContext context, {Moto? motoParaEditar}) async {
    final provider = context.read<MotoProvider>();

    final resultado = await showDialog<Moto>(
      context: context,
      builder: (_) => _FormularioMotoDialog(motoParaEditar: motoParaEditar),
    );

    if (resultado == null) return;

    if (motoParaEditar != null) {
      // Se o avatar foi trocado, apaga o arquivo antigo (órfão).
      if (resultado.imagemPath != motoParaEditar.imagemPath) {
        await ImagemMotoService.excluirSeExistir(motoParaEditar.imagemPath);
      }
      await DatabaseHelper.instance.atualizarMoto(resultado.copyWith(id: motoParaEditar.id));
      await provider.carregar();
    } else {
      final novoId = await DatabaseHelper.instance.inserirMoto(resultado);
      await provider.carregar(selecionarId: novoId);
    }
  }
}

class _FormularioMotoDialog extends StatefulWidget {
  final Moto? motoParaEditar;

  const _FormularioMotoDialog({this.motoParaEditar});

  @override
  State<_FormularioMotoDialog> createState() => _FormularioMotoDialogState();
}

class _FormularioMotoDialogState extends State<_FormularioMotoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _apelidoController;
  late final TextEditingController _intervaloController;

  String? _imagemPath;
  bool _selecionandoImagem = false;

  @override
  void initState() {
    super.initState();
    final item = widget.motoParaEditar;
    _nomeController = TextEditingController(text: item?.nome ?? '');
    _apelidoController = TextEditingController(text: item?.apelidoOuPlaca ?? '');
    _intervaloController = TextEditingController(
      text: (item?.intervaloTrocaOleo ?? 3000).toStringAsFixed(0),
    );
    _imagemPath = item?.imagemPath;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _apelidoController.dispose();
    _intervaloController.dispose();
    super.dispose();
  }

  Future<void> _selecionarImagem() async {
    setState(() => _selecionandoImagem = true);
    try {
      final caminho = await ImagemMotoService.selecionarECopiar();
      if (caminho != null) {
        setState(() => _imagemPath = caminho);
      }
    } finally {
      if (mounted) setState(() => _selecionandoImagem = false);
    }
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    final moto = Moto(
      nome: _nomeController.text.trim(),
      apelidoOuPlaca: _apelidoController.text.trim(),
      intervaloTrocaOleo: double.parse(_intervaloController.text.replaceAll(',', '.')),
      imagemPath: _imagemPath,
    );
    Navigator.of(context).pop(moto);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Usa um Moto "de rascunho" só para o preview do avatar, refletindo a
    // imagem já selecionada nesta sessão do formulário.
    final motoPreview = Moto(nome: _nomeController.text, imagemPath: _imagemPath);

    return AlertDialog(
      title: Text(widget.motoParaEditar != null ? 'Editar Motocicleta' : 'Nova Motocicleta'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    MotoAvatar(moto: motoPreview, raio: 44),
                    if (_selecionandoImagem)
                      const Positioned.fill(
                        child: CircleAvatar(
                          backgroundColor: Colors.black38,
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Material(
                        color: cs.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _selecionandoImagem ? null : _selecionarImagem,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(Icons.photo_camera_outlined, size: 16, color: cs.onPrimary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome (ex: CG 160, Honda Biz)'),
                onChanged: (_) => setState(() {}),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe um nome' : null,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _apelidoController,
                decoration: const InputDecoration(labelText: 'Apelido ou placa (opcional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _intervaloController,
                decoration: const InputDecoration(
                  labelText: 'Intervalo de troca de óleo (km)',
                  suffixText: 'km',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final valor = double.tryParse((v ?? '').replaceAll(',', '.'));
                  return (valor == null || valor <= 0) ? 'Informe um valor válido' : null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _salvar, child: const Text('Salvar')),
      ],
    );
  }
}
