/// Modelo de dados que representa um registro de abastecimento da motocicleta.
class Abastecimento {
  final int? id;
  final int motoId;
  final DateTime data;
  final double quilometragem;
  final double valorTotal;
  final double precoLitro;
  final double litros;

  Abastecimento({
    this.id,
    required this.motoId,
    required this.data,
    required this.quilometragem,
    required this.valorTotal,
    required this.precoLitro,
    required this.litros,
  });

  /// Converte o objeto para um Map, pronto para ser inserido no SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'moto_id': motoId,
      'data': data.toIso8601String(),
      'quilometragem': quilometragem,
      'valor_total': valorTotal,
      'preco_litro': precoLitro,
      'litros': litros,
    };
  }

  /// Cria um objeto Abastecimento a partir de um Map vindo do SQLite.
  factory Abastecimento.fromMap(Map<String, dynamic> map) {
    return Abastecimento(
      id: map['id'] as int?,
      motoId: map['moto_id'] as int,
      data: DateTime.parse(map['data'] as String),
      quilometragem: (map['quilometragem'] as num).toDouble(),
      valorTotal: (map['valor_total'] as num).toDouble(),
      precoLitro: (map['preco_litro'] as num).toDouble(),
      litros: (map['litros'] as num).toDouble(),
    );
  }

  Abastecimento copyWith({
    int? id,
    int? motoId,
    DateTime? data,
    double? quilometragem,
    double? valorTotal,
    double? precoLitro,
    double? litros,
  }) {
    return Abastecimento(
      id: id ?? this.id,
      motoId: motoId ?? this.motoId,
      data: data ?? this.data,
      quilometragem: quilometragem ?? this.quilometragem,
      valorTotal: valorTotal ?? this.valorTotal,
      precoLitro: precoLitro ?? this.precoLitro,
      litros: litros ?? this.litros,
    );
  }
}
