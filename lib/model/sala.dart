enum TipoSala { sala, laboratorio }

/// Ambiente que pode ser reservado (sala de aula ou laboratório).
class Sala {
  final String numero;
  final TipoSala tipo;
  final String andar;

  const Sala({required this.numero, required this.tipo, required this.andar});

  bool get ehLaboratorio => tipo == TipoSala.laboratorio;

  /// Rótulo curto usado no botão e nos cards. Ex.: `Sala` / `Lab.`
  String get rotuloCurto => ehLaboratorio ? 'Lab.' : 'Sala';

  /// Descrição completa mostrada no modal. Ex.: `Sala de Aula 308 - 3º Andar`
  String get descricao {
    final tipoTexto = ehLaboratorio ? 'Laboratório' : 'Sala de Aula';
    return '$tipoTexto $numero - $andar';
  }
}
