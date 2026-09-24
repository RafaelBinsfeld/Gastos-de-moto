/// Modelo de dados que representa um registro de manutenção da motocicleta.
class Manutencao {
  final int? id;
  final int motoId;
  final DateTime data;
  final double quilometragem;
  final String tipoServico; // ex: Troca de Óleo, Filtro de Ar, Kit Relação
  final double valorPeca;
  final double valorMaoDeObra;
  final String observacao;

  Manutencao({
    this.id,
    required this.motoId,
    required this.data,
    required this.quilometragem,
    required this.tipoServico,
    required this.valorPeca,
    required this.valorMaoDeObra,
    this.observacao = '',
  });

  /// Custo total do serviço (peça + mão de obra).
  double get custoTotal => valorPeca + valorMaoDeObra;

  /// Converte o objeto para um Map, pronto para ser inserido no SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'moto_id': motoId,
      'data': data.toIso8601String(),
      'quilometragem': quilometragem,
      'tipo_servico': tipoServico,
      'valor_peca': valorPeca,
      'valor_mao_obra': valorMaoDeObra,
      'observacao': observacao,
    };
  }

  /// Cria um objeto Manutencao a partir de um Map vindo do SQLite.
  factory Manutencao.fromMap(Map<String, dynamic> map) {
    return Manutencao(
      id: map['id'] as int?,
      motoId: map['moto_id'] as int,
      data: DateTime.parse(map['data'] as String),
      quilometragem: (map['quilometragem'] as num).toDouble(),
      tipoServico: map['tipo_servico'] as String,
      valorPeca: (map['valor_peca'] as num).toDouble(),
      valorMaoDeObra: (map['valor_mao_obra'] as num).toDouble(),
      observacao: (map['observacao'] as String?) ?? '',
    );
  }

  Manutencao copyWith({
    int? id,
    int? motoId,
    DateTime? data,
    double? quilometragem,
    String? tipoServico,
    double? valorPeca,
    double? valorMaoDeObra,
    String? observacao,
  }) {
    return Manutencao(
      id: id ?? this.id,
      motoId: motoId ?? this.motoId,
      data: data ?? this.data,
      quilometragem: quilometragem ?? this.quilometragem,
      tipoServico: tipoServico ?? this.tipoServico,
      valorPeca: valorPeca ?? this.valorPeca,
      valorMaoDeObra: valorMaoDeObra ?? this.valorMaoDeObra,
      observacao: observacao ?? this.observacao,
    );
  }
}
