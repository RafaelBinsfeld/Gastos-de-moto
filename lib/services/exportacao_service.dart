import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';

class ExportacaoService {
  static Future<void> exportarParaCSV({
    required List<Map<String, dynamic>> abastecimentos,
    required List<Map<String, dynamic>> manutencoes,
  }) async {
    List<List<dynamic>> rows = [];

    rows.add(["--- ABASTECIMENTOS ---"]);
    rows.add(["ID", "Data", "Valor (R\$)", "Litros", "KM Atual"]);
    for (var item in abastecimentos) {
      rows.add([
        item['id'] ?? '',
        item['data'] ?? '',
        item['valor'] ?? '',
        item['litros'] ?? '',
        item['km'] ?? ''
      ]);
    }

    rows.add([]);

    rows.add(["--- MANUTENÇÕES ---"]);
    rows.add(["ID", "Data", "Descrição", "Valor (R\$)", "KM Atual"]);
    for (var item in manutencoes) {
      rows.add([
        item['id'] ?? '',
        item['data'] ?? '',
        item['descricao'] ?? '',
        item['valor'] ?? '',
        item['km'] ?? ''
      ]);
    }

    String csvContent = const ListToCsvConverter().convert(rows);

    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/backup_moto_gastos.csv";
    final file = File(path);
    await file.writeAsString(csvContent);

    // Uso correto do ShareParams no share_plus
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        text: 'Backup dos dados do aplicativo Moto Gastos',
      ),
    );
  }

  static Future<void> exportarAbastecimentosCsv(int? motoId) async {
    final db = await DatabaseHelper.instance.database;
    List<Map<String, dynamic>> list;
    if (motoId != null) {
      list = await db.query('abastecimentos', where: 'moto_id = ?', whereArgs: [motoId]);
    } else {
      list = await db.query('abastecimentos');
    }
    await exportarParaCSV(abastecimentos: list, manutencoes: []);
  }

  static Future<void> exportarManutencoesCsv(int? motoId) async {
    final db = await DatabaseHelper.instance.database;
    List<Map<String, dynamic>> list;
    if (motoId != null) {
      list = await db.query('manutencoes', where: 'moto_id = ?', whereArgs: [motoId]);
    } else {
      list = await db.query('manutencoes');
    }
    await exportarParaCSV(abastecimentos: [], manutencoes: list);
  }
}