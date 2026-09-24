/// Modelo de dados que representa uma motocicleta cadastrada no aplicativo.
/// Cada motocicleta tem seu próprio histórico de abastecimentos e
/// manutenções, além de seu próprio intervalo configurado para troca de óleo.
class Moto {
  final int? id;
  final String nome;
  final String? apelidoOuPlaca;
  final double intervaloTrocaOleo;
  final String? imagemPath;

  Moto({
    this.id,
    required this.nome,
    this.apelidoOuPlaca,
    this.intervaloTrocaOleo = 3000,
    this.imagemPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'apelido': apelidoOuPlaca,
      'intervalo_troca_oleo': intervaloTrocaOleo,
      'imagem_path': imagemPath,
    };
  }

  factory Moto.fromMap(Map<String, dynamic> map) {
    return Moto(
      id: map['id'] as int?,
      nome: map['nome'] as String,
      apelidoOuPlaca: map['apelido'] as String?,
      intervaloTrocaOleo: (map['intervalo_troca_oleo'] as num?)?.toDouble() ?? 3000,
      imagemPath: map['imagem_path'] as String?,
    );
  }

  Moto copyWith({
    int? id,
    String? nome,
    String? apelidoOuPlaca,
    double? intervaloTrocaOleo,
    String? imagemPath,
    bool removerImagem = false,
  }) {
    return Moto(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      apelidoOuPlaca: apelidoOuPlaca ?? this.apelidoOuPlaca,
      intervaloTrocaOleo: intervaloTrocaOleo ?? this.intervaloTrocaOleo,
      imagemPath: removerImagem ? null : (imagemPath ?? this.imagemPath),
    );
  }
}
