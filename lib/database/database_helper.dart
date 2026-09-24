import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/abastecimento_model.dart';
import '../models/manutencao_model.dart';
import '../models/moto_model.dart';

/// Classe responsável por criar, abrir e executar comandos SQL no banco
/// de dados local (SQLite) do aplicativo.
///
/// A partir da versão 2 do schema, o app suporta múltiplas motocicletas:
/// cada abastecimento e manutenção pertence a uma moto (moto_id), e cada
/// moto tem seu próprio intervalo configurado para troca de óleo.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const int _versaoSchema = 3;

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'moto_gastos.db');

    return openDatabase(
      path,
      version: _versaoSchema,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE motos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        apelido TEXT,
        intervalo_troca_oleo REAL NOT NULL DEFAULT 3000,
        imagem_path TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE abastecimentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        moto_id INTEGER NOT NULL,
        data TEXT NOT NULL,
        quilometragem REAL NOT NULL,
        valor_total REAL NOT NULL,
        preco_litro REAL NOT NULL,
        litros REAL NOT NULL,
        FOREIGN KEY (moto_id) REFERENCES motos (id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE manutencoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        moto_id INTEGER NOT NULL,
        data TEXT NOT NULL,
        quilometragem REAL NOT NULL,
        tipo_servico TEXT NOT NULL,
        valor_peca REAL NOT NULL,
        valor_mao_obra REAL NOT NULL,
        observacao TEXT,
        FOREIGN KEY (moto_id) REFERENCES motos (id) ON DELETE CASCADE
      );
    ''');
  }

  /// Migra instalações antigas (schema v1, sem suporte a múltiplas motos)
  /// para o schema v2: cria a tabela `motos`, adiciona a coluna `moto_id`
  /// nas tabelas existentes e associa todos os registros antigos a uma
  /// moto padrão criada automaticamente.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE motos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT NOT NULL,
          apelido TEXT,
          intervalo_troca_oleo REAL NOT NULL DEFAULT 3000
        );
      ''');

      final motoPadraoId = await db.insert('motos', {
        'nome': 'Minha Moto',
        'apelido': null,
        'intervalo_troca_oleo': 3000,
      });

      await db.execute('ALTER TABLE abastecimentos ADD COLUMN moto_id INTEGER');
      await db.execute('ALTER TABLE manutencoes ADD COLUMN moto_id INTEGER');

      await db.update('abastecimentos', {'moto_id': motoPadraoId});
      await db.update('manutencoes', {'moto_id': motoPadraoId});
    }

    if (oldVersion < 3) {
      await db.execute('ALTER TABLE motos ADD COLUMN imagem_path TEXT');
    }
  }

  // ---------------------------------------------------------------------
  // CRUD - Motos
  // ---------------------------------------------------------------------

  Future<int> inserirMoto(Moto moto) async {
    final db = await database;
    final map = moto.toMap()..remove('id');
    return db.insert('motos', map);
  }

  Future<List<Moto>> obterMotos() async {
    final db = await database;
    final maps = await db.query('motos', orderBy: 'nome COLLATE NOCASE ASC');
    return maps.map((m) => Moto.fromMap(m)).toList();
  }

  Future<int> atualizarMoto(Moto moto) async {
    final db = await database;
    return db.update('motos', moto.toMap(), where: 'id = ?', whereArgs: [moto.id]);
  }

  /// Exclui uma moto e, em cascata (via FOREIGN KEY ON DELETE CASCADE),
  /// todos os abastecimentos e manutenções vinculados a ela.
  Future<int> deletarMoto(int id) async {
    final db = await database;
    return db.delete('motos', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------------------------
  // CRUD - Abastecimentos
  // ---------------------------------------------------------------------

  Future<int> inserirAbastecimento(Abastecimento item) async {
    final db = await database;
    final map = item.toMap()..remove('id');
    return db.insert('abastecimentos', map);
  }

  /// Lista os abastecimentos de uma moto, do mais recente para o mais
  /// antigo, com filtro opcional por período.
  Future<List<Abastecimento>> obterAbastecimentos({
    required int motoId,
    DateTime? inicio,
    DateTime? fim,
  }) async {
    final db = await database;
    final where = StringBuffer('moto_id = ?');
    final args = <Object?>[motoId];

    if (inicio != null) {
      where.write(' AND data >= ?');
      args.add(inicio.toIso8601String());
    }
    if (fim != null) {
      where.write(' AND data <= ?');
      args.add(fim.toIso8601String());
    }

    final maps = await db.query(
      'abastecimentos',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'quilometragem DESC',
    );
    return maps.map((m) => Abastecimento.fromMap(m)).toList();
  }

  Future<int> atualizarAbastecimento(Abastecimento item) async {
    final db = await database;
    return db.update('abastecimentos', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> deletarAbastecimento(int id) async {
    final db = await database;
    return db.delete('abastecimentos', where: 'id = ?', whereArgs: [id]);
  }

  /// Retorna o abastecimento imediatamente anterior a uma dada quilometragem
  /// (dentro da mesma moto), usado para calcular consumo e custo por km.
  Future<Abastecimento?> obterAbastecimentoAnterior(int motoId, double quilometragemAtual) async {
    final db = await database;
    final maps = await db.query(
      'abastecimentos',
      where: 'moto_id = ? AND quilometragem < ?',
      whereArgs: [motoId, quilometragemAtual],
      orderBy: 'quilometragem DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Abastecimento.fromMap(maps.first);
  }

  // ---------------------------------------------------------------------
  // CRUD - Manutenções
  // ---------------------------------------------------------------------

  Future<int> inserirManutencao(Manutencao item) async {
    final db = await database;
    final map = item.toMap()..remove('id');
    return db.insert('manutencoes', map);
  }

  /// Lista as manutenções de uma moto, da mais recente para a mais antiga,
  /// com filtros opcionais por período e por tipo de serviço.
  Future<List<Manutencao>> obterManutencoes({
    required int motoId,
    DateTime? inicio,
    DateTime? fim,
    String? tipoServico,
  }) async {
    final db = await database;
    final where = StringBuffer('moto_id = ?');
    final args = <Object?>[motoId];

    if (inicio != null) {
      where.write(' AND data >= ?');
      args.add(inicio.toIso8601String());
    }
    if (fim != null) {
      where.write(' AND data <= ?');
      args.add(fim.toIso8601String());
    }
    if (tipoServico != null && tipoServico.isNotEmpty) {
      where.write(' AND tipo_servico = ?');
      args.add(tipoServico);
    }

    final maps = await db.query(
      'manutencoes',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'quilometragem DESC',
    );
    return maps.map((m) => Manutencao.fromMap(m)).toList();
  }

  Future<int> atualizarManutencao(Manutencao item) async {
    final db = await database;
    return db.update('manutencoes', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> deletarManutencao(int id) async {
    final db = await database;
    return db.delete('manutencoes', where: 'id = ?', whereArgs: [id]);
  }

  /// Retorna a última manutenção registrada de um determinado tipo de
  /// serviço (ex: "Troca de Óleo") para uma moto específica.
  Future<Manutencao?> obterUltimaManutencaoPorTipo(int motoId, String tipoServico) async {
    final db = await database;
    final maps = await db.query(
      'manutencoes',
      where: 'moto_id = ? AND tipo_servico = ?',
      whereArgs: [motoId, tipoServico],
      orderBy: 'quilometragem DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Manutencao.fromMap(maps.first);
  }

  /// Retorna a lista de tipos de serviço já utilizados nas manutenções de
  /// uma moto, para alimentar filtros dinâmicos nas telas de histórico.
  Future<List<String>> obterTiposServicoDistintos(int motoId) async {
    final db = await database;
    final maps = await db.query(
      'manutencoes',
      distinct: true,
      columns: ['tipo_servico'],
      where: 'moto_id = ?',
      whereArgs: [motoId],
      orderBy: 'tipo_servico COLLATE NOCASE ASC',
    );
    return maps.map((m) => m['tipo_servico'] as String).toList();
  }

  // ---------------------------------------------------------------------
  // Consultas agregadas (usadas nas telas de Home e Relatórios)
  // ---------------------------------------------------------------------

  /// Maior quilometragem já registrada para uma moto, seja em
  /// abastecimento ou manutenção.
  Future<double> obterUltimaQuilometragem(int motoId) async {
    final db = await database;
    final resultAbast = await db.rawQuery(
      'SELECT MAX(quilometragem) as valor FROM abastecimentos WHERE moto_id = ?',
      [motoId],
    );
    final resultManut = await db.rawQuery(
      'SELECT MAX(quilometragem) as valor FROM manutencoes WHERE moto_id = ?',
      [motoId],
    );

    final maiorAbast = (resultAbast.first['valor'] as num?)?.toDouble() ?? 0;
    final maiorManut = (resultManut.first['valor'] as num?)?.toDouble() ?? 0;

    return maiorAbast > maiorManut ? maiorAbast : maiorManut;
  }

  /// Soma o valor total gasto com combustível por uma moto, opcionalmente
  /// filtrado por período.
  Future<double> obterTotalGastoCombustivel(int motoId, {DateTime? inicio, DateTime? fim}) async {
    final db = await database;
    final where = StringBuffer('moto_id = ?');
    final args = <Object?>[motoId];

    if (inicio != null && fim != null) {
      where.write(' AND data >= ? AND data <= ?');
      args.addAll([inicio.toIso8601String(), fim.toIso8601String()]);
    }

    final result = await db.rawQuery(
      'SELECT SUM(valor_total) as total FROM abastecimentos WHERE $where',
      args,
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  /// Soma o valor total gasto com manutenções (peças + mão de obra) por uma
  /// moto, opcionalmente filtrado por período.
  Future<double> obterTotalGastoManutencao(int motoId, {DateTime? inicio, DateTime? fim}) async {
    final db = await database;
    final where = StringBuffer('moto_id = ?');
    final args = <Object?>[motoId];

    if (inicio != null && fim != null) {
      where.write(' AND data >= ? AND data <= ?');
      args.addAll([inicio.toIso8601String(), fim.toIso8601String()]);
    }

    final result = await db.rawQuery(
      'SELECT SUM(valor_peca + valor_mao_obra) as total FROM manutencoes WHERE $where',
      args,
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  /// Retorna os gastos totais (combustível e manutenção) agregados por mês,
  /// para os últimos [meses] meses (incluindo o mês atual), de uma moto
  /// específica. Usado para alimentar o gráfico de evolução de gastos.
  Future<List<GastoMensal>> obterGastosMensais(int motoId, int meses) async {
    final db = await database;
    final agora = DateTime.now();

    final resultado = <GastoMensal>[];
    for (int i = meses - 1; i >= 0; i--) {
      final referencia = DateTime(agora.year, agora.month - i, 1);
      final inicioMes = DateTime(referencia.year, referencia.month, 1);
      final fimMes = DateTime(referencia.year, referencia.month + 1, 1)
          .subtract(const Duration(seconds: 1));

      final combustivelResult = await db.rawQuery(
        'SELECT SUM(valor_total) as total FROM abastecimentos '
        'WHERE moto_id = ? AND data >= ? AND data <= ?',
        [motoId, inicioMes.toIso8601String(), fimMes.toIso8601String()],
      );
      final manutencaoResult = await db.rawQuery(
        'SELECT SUM(valor_peca + valor_mao_obra) as total FROM manutencoes '
        'WHERE moto_id = ? AND data >= ? AND data <= ?',
        [motoId, inicioMes.toIso8601String(), fimMes.toIso8601String()],
      );

      resultado.add(GastoMensal(
        mesReferencia: inicioMes,
        combustivel: (combustivelResult.first['total'] as num?)?.toDouble() ?? 0,
        manutencao: (manutencaoResult.first['total'] as num?)?.toDouble() ?? 0,
      ));
    }

    return resultado;
  }
}

/// Representa o total gasto em um mês específico, separado por categoria.
class GastoMensal {
  final DateTime mesReferencia;
  final double combustivel;
  final double manutencao;

  GastoMensal({
    required this.mesReferencia,
    required this.combustivel,
    required this.manutencao,
  });

  double get total => combustivel + manutencao;
}
