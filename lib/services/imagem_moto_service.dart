import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Serviço responsável por deixar o usuário escolher uma imagem (avatar)
/// para representar uma motocicleta, copiando o arquivo escolhido para uma
/// pasta própria do app (já que o caminho original, vindo da galeria ou de
/// outro app, pode não continuar acessível depois).
class ImagemMotoService {
  static const List<String> _extensoesAceitas = ['jpg', 'jpeg', 'png', 'webp'];

  /// Abre o seletor de arquivos do sistema filtrando por imagens, copia o
  /// arquivo escolhido para a pasta `moto_images` dentro do diretório de
  /// documentos do app e retorna o novo caminho salvo. Retorna `null` se o
  /// usuário cancelar a seleção.
  static Future<String?> selecionarECopiar() async {
    final resultado = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _extensoesAceitas,
      withData: true,
    );
    if (resultado == null || resultado.files.isEmpty) return null;

    final arquivoEscolhido = resultado.files.first;
    final bytes = arquivoEscolhido.bytes;
    if (bytes == null) return null;

    final diretorioDocs = await getApplicationDocumentsDirectory();
    final pastaImagens = Directory(p.join(diretorioDocs.path, 'moto_images'));
    if (!await pastaImagens.exists()) {
      await pastaImagens.create(recursive: true);
    }

    final extensao = p.extension(arquivoEscolhido.name).isNotEmpty
        ? p.extension(arquivoEscolhido.name)
        : '.jpg';
    final nomeArquivo = 'moto_${DateTime.now().millisecondsSinceEpoch}$extensao';
    final destino = File(p.join(pastaImagens.path, nomeArquivo));

    await destino.writeAsBytes(bytes);
    return destino.path;
  }

  /// Remove o arquivo de imagem salvo (ignora silenciosamente se não
  /// existir mais), usado ao trocar ou remover o avatar de uma moto.
  static Future<void> excluirSeExistir(String? caminho) async {
    if (caminho == null || caminho.isEmpty) return;
    try {
      final arquivo = File(caminho);
      if (await arquivo.exists()) {
        await arquivo.delete();
      }
    } catch (_) {
      // Falha ao excluir um arquivo órfão não deve interromper o fluxo do app.
    }
  }
}
