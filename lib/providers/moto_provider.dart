import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/moto_model.dart';
import '../services/preferencias_service.dart';

/// Mantém em memória a lista de motocicletas cadastradas e qual delas está
/// selecionada no momento, notificando as telas quando isso muda (troca de
/// moto, moto criada/editada/excluída).
///
/// Se o usuário ainda não tiver nenhuma moto cadastrada, uma moto padrão
/// ("Minha Moto") é criada automaticamente na primeira execução.
class MotoProvider extends ChangeNotifier {
  List<Moto> _motos = [];
  Moto? _motoAtual;
  bool _carregando = true;

  List<Moto> get motos => _motos;
  Moto? get motoAtual => _motoAtual;
  bool get carregando => _carregando;
  bool get temMultiplasMotos => _motos.length > 1;

  /// Carrega (ou recarrega) a lista de motos do banco de dados.
  /// [selecionarId] força a seleção de uma moto específica (ex: recém-criada).
  Future<void> carregar({int? selecionarId}) async {
    _carregando = true;
    notifyListeners();

    var motos = await DatabaseHelper.instance.obterMotos();

    if (motos.isEmpty) {
      await DatabaseHelper.instance.inserirMoto(Moto(nome: 'Minha Moto'));
      motos = await DatabaseHelper.instance.obterMotos();
    }

    _motos = motos;

    final idPreferido = selecionarId ?? _motoAtual?.id ?? await PreferenciasService.obterMotoSelecionadaId();
    final selecionada = _motos.firstWhere(
      (m) => m.id == idPreferido,
      orElse: () => _motos.first,
    );

    _motoAtual = selecionada;
    if (selecionada.id != null) {
      await PreferenciasService.definirMotoSelecionadaId(selecionada.id!);
    }

    _carregando = false;
    notifyListeners();
  }

  /// Troca a moto atualmente selecionada, persistindo a escolha.
  Future<void> selecionar(Moto moto) async {
    if (_motoAtual?.id == moto.id) return;
    _motoAtual = moto;
    if (moto.id != null) {
      await PreferenciasService.definirMotoSelecionadaId(moto.id!);
    }
    notifyListeners();
  }
}
