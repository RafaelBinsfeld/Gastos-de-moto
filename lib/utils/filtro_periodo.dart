/// Opções de filtro por período, usadas tanto na tela de Histórico quanto
/// na tela de Relatórios.
enum FiltroPeriodo { todos, esteMes, ultimos3Meses, ultimos6Meses, esteAno }

extension FiltroPeriodoExtensao on FiltroPeriodo {
  String get rotulo {
    switch (this) {
      case FiltroPeriodo.todos:
        return 'Todos';
      case FiltroPeriodo.esteMes:
        return 'Este mês';
      case FiltroPeriodo.ultimos3Meses:
        return 'Últimos 3 meses';
      case FiltroPeriodo.ultimos6Meses:
        return 'Últimos 6 meses';
      case FiltroPeriodo.esteAno:
        return 'Este ano';
    }
  }

  /// Data de início do período (null significa "sem limite inferior").
  DateTime? get inicio {
    final agora = DateTime.now();
    switch (this) {
      case FiltroPeriodo.todos:
        return null;
      case FiltroPeriodo.esteMes:
        return DateTime(agora.year, agora.month, 1);
      case FiltroPeriodo.ultimos3Meses:
        return DateTime(agora.year, agora.month - 2, 1);
      case FiltroPeriodo.ultimos6Meses:
        return DateTime(agora.year, agora.month - 5, 1);
      case FiltroPeriodo.esteAno:
        return DateTime(agora.year, 1, 1);
    }
  }
}
