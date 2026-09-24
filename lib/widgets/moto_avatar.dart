import 'dart:io';

import 'package:flutter/material.dart';

import '../models/moto_model.dart';

/// Avatar circular de uma moto: mostra a imagem importada pelo usuário
/// quando existe, ou um ícone de fallback dentro de um círculo colorido
/// (na cor de destaque do tema) quando a moto ainda não tem foto.
class MotoAvatar extends StatelessWidget {
  final Moto? moto;
  final double raio;
  final Color? corFundo;

  const MotoAvatar({super.key, required this.moto, this.raio = 20, this.corFundo});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final caminho = moto?.imagemPath;

    if (caminho != null && caminho.isNotEmpty && File(caminho).existsSync()) {
      return CircleAvatar(
        radius: raio,
        backgroundColor: cs.surfaceContainerHighest,
        backgroundImage: FileImage(File(caminho)),
      );
    }

    return CircleAvatar(
      radius: raio,
      backgroundColor: corFundo ?? cs.primary.withOpacity(0.18),
      child: Icon(Icons.two_wheeler, color: cs.primary, size: raio),
    );
  }
}
