import 'package:cloud_firestore/cloud_firestore.dart';

import 'conflitos.dart';
import '../model/disciplina.dart';
import '../model/matricula.dart';

/// Erro de matrícula já traduzido para mostrar na tela.
class ErroMatricula implements Exception {
  final String mensagem;
  const ErroMatricula(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Matrículas dos alunos nas disciplinas, e o período de inscrição.
abstract class MatriculaService {
  static MatriculaService instancia = FirebaseMatriculaService();

  /// Período de inscrição atual, sempre atualizado.
  Stream<PeriodoMatricula> periodo();

  /// Salva o período (administrador). Lança [ErroMatricula].
  Future<void> salvarPeriodo(PeriodoMatricula periodo);

  /// Matrículas do aluno, sempre atualizadas.
  Stream<List<Matricula>> doAluno(String alunoId);

  /// Matrículas de uma disciplina, sempre atualizadas.
  Stream<List<Matricula>> daDisciplina(String disciplinaId);

  /// Matricula o aluno na disciplina. Lança [ErroMatricula].
  ///
  /// Quem confere período e semestre liberado é a tela do aluno (e, depois de
  /// publicadas, as regras do Firestore). O administrador matricula sem essa
  /// restrição.
  Future<void> matricular(String alunoId, Disciplina disciplina);

  /// Cancela a matrícula. Lança [ErroMatricula].
  Future<void> cancelar(String alunoId, String disciplinaId);
}

class FirebaseMatriculaService implements MatriculaService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _colecao =>
      _db.collection('matriculas');
  DocumentReference<Map<String, dynamic>> get _config =>
      _db.collection('config').doc('matricula');

  List<Matricula> _converter(QuerySnapshot<Map<String, dynamic>> r) => [
    for (final doc in r.docs) Matricula.fromMap(doc.id, doc.data()),
  ];

  @override
  Stream<PeriodoMatricula> periodo() =>
      _config.snapshots().map((doc) => PeriodoMatricula.fromMap(doc.data()));

  @override
  Future<void> salvarPeriodo(PeriodoMatricula periodo) async {
    final inicio = periodo.inicio;
    final fim = periodo.fim;
    if (inicio != null && fim != null && fim.isBefore(inicio)) {
      throw const ErroMatricula('O fim do período vem antes do início.');
    }
    try {
      await _config.set({
        ...periodo.toMap(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ErroMatricula(_traduzir(e.code));
    }
  }

  @override
  Stream<List<Matricula>> doAluno(String alunoId) =>
      _colecao.where('alunoId', isEqualTo: alunoId).snapshots().map(_converter);

  @override
  Stream<List<Matricula>> daDisciplina(String disciplinaId) => _colecao
      .where('disciplinaId', isEqualTo: disciplinaId)
      .snapshots()
      .map(_converter);

  @override
  Future<void> matricular(String alunoId, Disciplina disciplina) async {
    try {
      // O aluno não pode ter aulas no mesmo bloco de outra disciplina sua.
      for (final aula in await Conflitos.horariosDaDisciplina(disciplina.id)) {
        final outra = await Conflitos.doAluno(
          alunoId,
          aula.dia,
          aula.turno,
          ignorarDisciplinaId: disciplina.id,
        );
        if (outra != null) {
          throw ErroMatricula(
            'Você já está matriculado em "${outra.disciplinaNome}", que tem aula '
            'na ${Conflitos.descrever(outra.dia, outra.turno)}, o mesmo horário '
            'de "${disciplina.nome}".',
          );
        }
      }

      await _colecao.doc(Matricula.idPara(alunoId, disciplina.id)).set({
        ...Matricula(
          alunoId: alunoId,
          disciplinaId: disciplina.id,
          cursoId: disciplina.cursoId,
          semestreId: disciplina.semestreId,
        ).toMap(),
        'criadoEm': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ErroMatricula(_traduzir(e.code));
    }
  }

  @override
  Future<void> cancelar(String alunoId, String disciplinaId) async {
    try {
      await _colecao.doc(Matricula.idPara(alunoId, disciplinaId)).delete();
    } on FirebaseException catch (e) {
      throw ErroMatricula(_traduzir(e.code));
    }
  }

  String _traduzir(String codigo) => switch (codigo) {
    'permission-denied' =>
      'Sem permissão. Fora do período de matrícula, ou verifique as regras '
          'do Firestore.',
    'unavailable' => 'Sem conexão. Verifique sua internet.',
    _ => 'Não foi possível salvar a matrícula ($codigo).',
  };
}
