import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/abastecimento_model.dart';
import '../models/manutencao_model.dart';
import '../theme/app_theme.dart';

final _formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _formatoData = DateFormat('dd/MM/yyyy');

/// Linha de abastecimento no novo visual: barra de destaque âmbar, sem o
/// ícone dentro de círculo genérico do ListTile padrão. Deslizar para a
/// esquerda exclui (com confirmação); tocar abre para edição.
class LinhaAbastecimento extends StatelessWidget {
  final Abastecimento abastecimento;
  final VoidCallback onTap;
  final VoidCallback onExcluido;

  const LinhaAbastecimento({
    super.key,
    required this.abastecimento,
    required this.onTap,
    required this.onExcluido,
  });

  @override
  Widget build(BuildContext context) {
    return _LinhaRegistro(
      dismissKey: ValueKey('abastecimento_${abastecimento.id}'),
      corAccent: CoresApp.ambarPainel,
      icone: Icons.local_gas_station,
      titulo: '${abastecimento.litros.toStringAsFixed(2)} L · ${_formatoMoeda.format(abastecimento.valorTotal)}',
      subtitulo: '${_formatoData.format(abastecimento.data)} • ${abastecimento.quilometragem.toStringAsFixed(0)} km',
      valorTrailing: null,
      onTap: onTap,
      mensagemExclusao: 'Este registro de ${_formatoData.format(abastecimento.data)} será removido permanentemente.',
      onExcluido: onExcluido,
    );
  }
}

/// Linha de manutenção no novo visual: barra de destaque em tom de aço.
class LinhaManutencao extends StatelessWidget {
  final Manutencao manutencao;
  final VoidCallback onTap;
  final VoidCallback onExcluido;

  const LinhaManutencao({
    super.key,
    required this.manutencao,
    required this.onTap,
    required this.onExcluido,
  });

  @override
  Widget build(BuildContext context) {
    return _LinhaRegistro(
      dismissKey: ValueKey('manutencao_${manutencao.id}'),
      corAccent: CoresApp.acoAsfalto,
      icone: Icons.build,
      titulo: manutencao.tipoServico,
      subtitulo: '${_formatoData.format(manutencao.data)} • ${manutencao.quilometragem.toStringAsFixed(0)} km',
      valorTrailing: _formatoMoeda.format(manutencao.custoTotal),
      onTap: onTap,
      mensagemExclusao: 'Este registro de "${manutencao.tipoServico}" será removido permanentemente.',
      onExcluido: onExcluido,
    );
  }
}

class _LinhaRegistro extends StatelessWidget {
  final Key dismissKey;
  final Color corAccent;
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final String? valorTrailing;
  final VoidCallback onTap;
  final String mensagemExclusao;
  final VoidCallback onExcluido;

  const _LinhaRegistro({
    required this.dismissKey,
    required this.corAccent,
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.valorTrailing,
    required this.onTap,
    required this.mensagemExclusao,
    required this.onExcluido,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dismissible(
      key: dismissKey,
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(color: cs.error, borderRadius: BorderRadius.circular(10)),
        child: Icon(Icons.delete_outline, color: cs.onError),
      ),
      confirmDismiss: (_) => _confirmar(context),
      onDismissed: (_) => onExcluido(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(width: 4, color: corAccent),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Icon(icone, size: 20, color: cs.onSurface.withOpacity(0.6)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(titulo, style: Theme.of(context).textTheme.titleSmall),
                                const SizedBox(height: 2),
                                Text(subtitulo, style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          if (valorTrailing != null) ...[
                            const SizedBox(width: 8),
                            Text(valorTrailing!, style: Theme.of(context).textTheme.titleSmall),
                          ],
                          const SizedBox(width: 6),
                          Icon(Icons.chevron_right, size: 18, color: cs.onSurface.withOpacity(0.35)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmar(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir registro?'),
        content: Text(mensagemExclusao),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    return confirmado ?? false;
  }
}

/// Estado vazio simples, usado quando uma lista de registros não tem itens
/// (respeitando o filtro atual, se houver).
class EstadoVazioRegistro extends StatelessWidget {
  final IconData icone;
  final String mensagem;

  const EstadoVazioRegistro({super.key, required this.icone, required this.mensagem});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icone, size: 32, color: cs.onSurface.withOpacity(0.3)),
          const SizedBox(height: 10),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}
