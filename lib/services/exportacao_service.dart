import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';

/// Serviço responsável por exportar os dados de abastecimentos e
/// manutenções de uma moto para arquivos CSV, permitindo backup ou
/// análise externa (ex: em uma planilha). O formato gerado aqui é o mesmo
/// esperado pelo `importacao_service.dart` ao restaurar um backup.
class ExportacaoService {
  static final _formatoData = DateFormat('dd/MM/yyyy');

  /// Gera um CSV com os abastecimentos de uma moto, salva em um arquivo
  /// temporário e abre a folha de compartilhamento do sistema.
  static Future<void> exportarAbastecimentosCsv(int motoId) async {
    final abastecimentos = await DatabaseHelper.instance.obterAbastecimentos(motoId: motoId);

    final linhas = <List<dynamic>>[
      ['Data', 'Quilometragem (km)', 'Valor Total (R\$)', 'Preço por Litro (R\$)', 'Litros'],
      ...abastecimentos.map((a) => [
            _formatoData.format(a.data),
            a.quilometragem,
            a.valorTotal,
            a.precoLitro,
            a.litros,
          ]),
    ];

    await _salvarECompartilhar(linhas, 'abastecimentos');
  }

  /// Gera um CSV com as manutenções de uma moto, salva em um arquivo
  /// temporário e abre a folha de compartilhamento do sistema.
  static Future<void> exportarManutencoesCsv(int motoId) async {
    final manutencoes = await DatabaseHelper.instance.obterManutencoes(motoId: motoId);

    final linhas = <List<dynamic>>[
      ['Data', 'Quilometragem (km)', 'Tipo de Serviço', 'Valor Peça (R\$)', 'Valor Mão de Obra (R\$)', 'Custo Total (R\$)', 'Observação'],
      ...manutencoes.map((m) => [
            _formatoData.format(m.data),
            m.quilometragem,
            m.tipoServico,
            m.valorPeca,
            m.valorMaoDeObra,
            m.custoTotal,
            m.observacao,
          ]),
    ];

    await _salvarECompartilhar(linhas, 'manutencoes');
  }

  static Future<void> _salvarECompartilhar(List<List<dynamic>> linhas, String nomeBase) async {
    final csv = const ListToCsvConverter().convert(linhas);

    final diretorio = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final arquivo = File('${diretorio.path}/${nomeBase}_$timestamp.csv');
    await arquivo.writeAsString(csv);

    await Share.shareXFiles(
      [XFile(arquivo.path)],
      subject: 'Exportação de $nomeBase - Minha Moto',
    );
  }
}
