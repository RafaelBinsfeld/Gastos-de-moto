import 'package:flutter/material.dart';
import '../models/moto_model.dart';
import '../database/database_helper.dart';

class MotoProvider extends ChangeNotifier {
  List<Moto> _motos = [];
  Moto? _motoAtual;
  bool _carregando = false;

  List<Moto> get motos => _motos;
  Moto? get motoAtual => _motoAtual;
  bool get carregando => _carregando;

  // Construtor: busca as motos no banco assim que o app inicia
  MotoProvider() {
    carregarMotos();
  }

  // Busca as motos no SQLite e aceita o parâmetro 'selecionarId'
  Future<void> carregarMotos({int? selecionarId}) async {
    _carregando = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query('motos');

      _motos = maps.map((map) => Moto.fromMap(map)).toList();

      if (_motos.isNotEmpty) {
        if (selecionarId != null) {
          _motoAtual = _motos.firstWhere(
            (m) => m.id == selecionarId,
            orElse: () => _motos.first,
          );
        } else if (_motoAtual == null) {
          _motoAtual = _motos.first;
        }
      } else {
        _motoAtual = null;
      }
    } catch (e) {
      debugPrint('Erro ao carregar motos do banco de dados: $e');
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  // Alias repassando o parâmetro 'selecionarId' para compatibilidade com motos_screen.dart
  Future<void> carregar({int? selecionarId}) => carregarMotos(selecionarId: selecionarId);

  void selecionar(Moto moto) {
    _motoAtual = moto;
    notifyListeners();
  }

  void selecionarId(int id) {
    try {
      _motoAtual = _motos.firstWhere((m) => m.id == id);
    } catch (_) {
      if (_motos.isNotEmpty) _motoAtual = _motos.first;
    }
    notifyListeners();
  }

  Future<void> adicionarMoto(Moto moto) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('motos', moto.toMap());
    await carregarMotos();
  }

  Future<void> atualizarMoto(Moto moto) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'motos',
      moto.toMap(),
      where: 'id = ?',
      whereArgs: [moto.id],
    );
    await carregarMotos();
  }

  Future<void> deletarMoto(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'motos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (_motoAtual?.id == id) {
      _motoAtual = null;
    }
    await carregarMotos();
  }
}