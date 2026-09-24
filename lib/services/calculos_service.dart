/// Status possível do alerta de troca de óleo.
enum StatusTrocaOleo { emDia, proxima, vencida }

/// Resultado do cálculo de alerta de troca de óleo.
class ResultadoAlertaOleo {
  final StatusTrocaOleo status;
  final double quilometragemProximaTroca;
  final double quilometragemRestante;

  ResultadoAlertaOleo({
    required this.status,
    required this.quilometragemProximaTroca,
    required this.quilometragemRestante,
  });
}

/// Serviço que concentra todas as regras de negócio e fórmulas de cálculo
/// do aplicativo (consumo, custo por km, custo de manutenção e alertas).
class CalculosService {
  /// Consumo médio (km/l) entre dois abastecimentos consecutivos.
  /// Consumo = (Quilometragem Atual - Quilometragem Anterior) / Litros Abastecidos Atual
  static double calcularConsumo({
    required double quilometragemAtual,
    required double quilometragemAnterior,
    required double litrosAtual,
  }) {
    final distancia = quilometragemAtual - quilometragemAnterior;
    if (litrosAtual <= 0 || distancia <= 0) return 0;
    return distancia / litrosAtual;
  }

  /// Custo por quilômetro rodado entre dois abastecimentos consecutivos.
  /// Custo por KM = Valor Total do Abastecimento / (Quilometragem Atual - Quilometragem Anterior)
  static double calcularCustoPorKm({
    required double valorTotal,
    required double quilometragemAtual,
    required double quilometragemAnterior,
  }) {
    final distancia = quilometragemAtual - quilometragemAnterior;
    if (distancia <= 0) return 0;
    return valorTotal / distancia;
  }

  /// Custo total de uma manutenção (peça + mão de obra).
  static double calcularCustoTotalManutencao({
    required double valorPeca,
    required double valorMaoDeObra,
  }) {
    return valorPeca + valorMaoDeObra;
  }

  /// Verifica o status da próxima troca de óleo com base na última troca
  /// registrada, no intervalo recomendado e na quilometragem atual.
  ///
  /// - Restante <= 0      -> manutenção vencida
  /// - Restante <= 500 km -> manutenção próxima
  /// - Caso contrário      -> em dia
  static ResultadoAlertaOleo verificarAlertaTrocaOleo({
    required double quilometragemUltimaTroca,
    required double intervaloRecomendado,
    required double quilometragemAtual,
  }) {
    final proximaTroca = quilometragemUltimaTroca + intervaloRecomendado;
    final restante = proximaTroca - quilometragemAtual;

    late StatusTrocaOleo status;
    if (restante <= 0) {
      status = StatusTrocaOleo.vencida;
    } else if (restante <= 500) {
      status = StatusTrocaOleo.proxima;
    } else {
      status = StatusTrocaOleo.emDia;
    }

    return ResultadoAlertaOleo(
      status: status,
      quilometragemProximaTroca: proximaTroca,
      quilometragemRestante: restante,
    );
  }
}
