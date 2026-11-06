enum TipoSala { sala, laboratorio }

/// Ambiente que pode ser reservado (sala de aula ou laboratório).
///
/// Fica na coleção `salas` do Firestore. O [id] do documento é montado com
/// [idPara], a partir do tipo e do número: assim a mesma sala não consegue
/// ser cadastrada duas vezes.
class Sala {
  final String id;
  final String numero;
  final TipoSala tipo;
  final String andar;

  const Sala({
    this.id = '',
    required this.numero,
    required this.tipo,
    required this.andar,
  });

  bool get ehLaboratorio => tipo == TipoSala.laboratorio;

  /// Rótulo curto usado no botão e nos cards. Ex.: `Sala` / `Lab.`
  String get rotuloCurto => ehLaboratorio ? 'Lab.' : 'Sala';

  /// Descrição completa mostrada no modal. Ex.: `Sala de Aula 308 - 3º Andar`
  String get descricao {
    final tipoTexto = ehLaboratorio ? 'Laboratório' : 'Sala de Aula';
    return '$tipoTexto $numero - $andar';
  }

  /// Id do documento no Firestore. Ex.: `sala-308`, `laboratorio-402`.
  static String idPara(String numero, TipoSala tipo) =>
      '${tipo.name}-${numero.trim().toUpperCase()}';

  Map<String, Object?> toMap() => {
    'numero': numero,
    'tipo': tipo.name,
    'andar': andar,
  };

  factory Sala.fromMap(String id, Map<String, dynamic> dados) {
    return Sala(
      id: id,
      numero: (dados['numero'] as String?) ?? '',
      tipo: TipoSala.values.firstWhere(
        (t) => t.name == dados['tipo'],
        orElse: () => TipoSala.sala,
      ),
      andar: (dados['andar'] as String?) ?? '',
    );
  }
}

/// Ordem da grade: primeiro as salas, depois os laboratórios, cada grupo pelo
/// número (301, 302, ..., 310 — e não 301, 310, 302).
int compararSalas(Sala a, Sala b) {
  if (a.tipo != b.tipo) return a.tipo.index.compareTo(b.tipo.index);

  final numeroA = int.tryParse(a.numero);
  final numeroB = int.tryParse(b.numero);
  if (numeroA != null && numeroB != null) return numeroA.compareTo(numeroB);

  return a.numero.compareTo(b.numero);
}
