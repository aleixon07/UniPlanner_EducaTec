/// Semestre de um curso (por exemplo, o "3º Semestre" de Sistemas de
/// Informação).
///
/// Fica na coleção `semestres` do Firestore, com id automático. O vínculo com o
/// curso é o [cursoId]: cada semestre pertence a um único curso, e um curso
/// não pode ter dois semestres com o mesmo [numero]. O id é estável mesmo
/// quando o número muda, para as disciplinas poderem apontar para ele.
class Semestre {
  final String id;
  final String cursoId;
  final int numero;

  const Semestre({
    required this.id,
    required this.cursoId,
    required this.numero,
  });

  /// Texto mostrado na tela. Ex.: `3º Semestre`
  String get rotulo => '$numeroº Semestre';

  Map<String, Object?> toMap() => {'cursoId': cursoId, 'numero': numero};

  factory Semestre.fromMap(String id, Map<String, dynamic> dados) {
    return Semestre(
      id: id,
      cursoId: (dados['cursoId'] as String?) ?? '',
      numero: (dados['numero'] as num?)?.toInt() ?? 0,
    );
  }
}
