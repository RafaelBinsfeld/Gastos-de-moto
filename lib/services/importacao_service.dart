import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../models/abastecimento_model.dart';
import '../models/manutencao_model.dart';

/// Resultado de uma operação de importação: quantos registros foram
/// importados com sucesso e quantas linhas do arquivo tiveram erro (e
/// foram ignoradas).
class ResultadoImportacao {
  final int registrosImportados;
  final int linhasComErro;

  ResultadoImportacao({required this.registrosImportados, required this.linhasComErro});
}

/// Serviço responsável por importar arquivos CSV (gerados pela própria
/// exportação do app, ver `exportacao_service.dart`) de volta para o banco
/// de dados local, permitindo restaurar um backup.
class ImportacaoService {
  static final _formatoData = DateFormat('dd/MM/yyyy');

  /// Abre o seletor de arquivos do sistema, lê um CSV de abastecimentos no
  /// formato exportado pelo app e insere os registros para a moto
  /// informada. Retorna `null` se o usuário cancelar a seleção.
  static Future<ResultadoImportacao?> importarAbastecimentosCsv(int motoId) async {
    final linhas = await _selecionarEDecodificarCsv();
    if (linhas == null) return null;

    int importados = 0;
    int comErro = 0;

    for (final linha in linhas.skip(1)) {
      if (linha.length < 5) {
        comErro++;
        continue;
      }
      try {
        final abastecimento = Abastecimento(
          motoId: motoId,
          data: _formatoData.parseStrict(linha[0].toString().trim()),
          quilometragem: _parseDouble(linha[1]),
          valorTotal: _parseDouble(linha[2]),
          precoLitro: _parseDouble(linha[3]),
          litros: _parseDouble(linha[4]),
        );
        await DatabaseHelper.instance.inserirAbastecimento(abastecimento);
        importados++;
      } catch (_) {
        comErro++;
      }
    }

    return ResultadoImportacao(registrosImportados: importados, linhasComErro: comErro);
  }

  /// Abre o seletor de arquivos do sistema, lê um CSV de manutenções no
  /// formato exportado pelo app e insere os registros para a moto
  /// informada. Retorna `null` se o usuário cancelar a seleção.
  static Future<ResultadoImportacao?> importarManutencoesCsv(int motoId) async {
    final linhas = await _selecionarEDecodificarCsv();
    if (linhas == null) return null;

    int importados = 0;
    int comErro = 0;

    for (final linha in linhas.skip(1)) {
      if (linha.length < 5) {
        comErro++;
        continue;
      }
      try {
        final manutencao = Manutencao(
          motoId: motoId,
          data: _formatoData.parseStrict(linha[0].toString().trim()),
          quilometragem: _parseDouble(linha[1]),
          tipoServico: linha[2].toString().trim(),
          valorPeca: _parseDouble(linha[3]),
          valorMaoDeObra: _parseDouble(linha[4]),
          // coluna [5] é o custo total (calculado, não precisa ser lido)
          observacao: linha.length > 6 ? linha[6].toString().trim() : '',
        );
        await DatabaseHelper.instance.inserirManutencao(manutencao);
        importados++;
      } catch (_) {
        comErro++;
      }
    }

    return ResultadoImportacao(registrosImportados: importados, linhasComErro: comErro);
  }

  static double _parseDouble(dynamic valor) {
    return double.parse(valor.toString().trim().replaceAll(',', '.'));
  }

  /// Abre o seletor de arquivos, lê o CSV escolhido como texto UTF-8 e o
  /// converte em uma lista de linhas/colunas. Retorna `null` se o usuário
  /// cancelar a seleção ou se o arquivo estiver vazio.
  static Future<List<List<dynamic>>?> _selecionarEDecodificarCsv() async {
    final resultado = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (resultado == null || resultado.files.isEmpty) return null;

    final bytes = resultado.files.first.bytes;
    if (bytes == null || bytes.isEmpty) return null;

    final conteudo = utf8.decode(bytes, allowMalformed: true);
    final linhas = const CsvToListConverter(shouldParseNumbers: false).convert(conteudo);
    if (linhas.isEmpty) return null;

    return linhas;
  }
}
