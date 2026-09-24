import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/moto_provider.dart';
import '../screens/motos_screen.dart';
import 'moto_avatar.dart';
import 'responsive_helpers.dart';

/// Ícone de ação para a AppBar que mostra a moto atualmente selecionada e
/// permite trocar rapidamente entre as motos cadastradas, além de abrir a
/// tela de gerenciamento de motocicletas.
class SeletorMotoAction extends StatelessWidget {
  const SeletorMotoAction({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MotoProvider>();
    final motoAtual = provider.motoAtual;

    if (motoAtual == null) return const SizedBox.shrink();

    return PopupMenuButton<int>(
      tooltip: 'Trocar motocicleta',
      icon: MotoAvatar(moto: motoAtual, raio: 15),
      onSelected: (valor) async {
        if (valor == -1) {
          await abrirTelaResponsiva(context, const MotosScreen());
          return;
        }
        final escolhida = provider.motos.firstWhere((m) => m.id == valor);
        provider.selecionar(escolhida);
      },
      itemBuilder: (context) => [
        for (final moto in provider.motos)
          PopupMenuItem(
            value: moto.id,
            child: Row(
              children: [
                MotoAvatar(moto: moto, raio: 14),
                const SizedBox(width: 10),
                Expanded(child: Text(moto.nome)),
                if (moto.id == motoAtual.id)
                  Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: -1,
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 20),
              SizedBox(width: 8),
              Text('Gerenciar motocicletas'),
            ],
          ),
        ),
      ],
    );
  }
}
