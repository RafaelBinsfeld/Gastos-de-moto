import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  static Future<void> exportarParaCSV({
    required List<Map<String, dynamic>> abastecimentos,
    required List<Map<String, dynamic>> manutencoes,
  }) async {
    List<List<dynamic>> rows = [];

    // Seção de Abastecimentos
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

    rows.add([]); // Linha em branco para separação

    // Seção de Manutenções
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

    await Share.shareXFiles(
      [XFile(path)],
      text: 'Backup dos dados do aplicativo Moto Gastos',
    );
  }
}