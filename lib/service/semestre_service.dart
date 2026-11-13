import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/semestre.dart';
import 'disciplina_service.dart';

/// Erro de semestre já traduzido para mostrar na tela.
class ErroSemestre implements Exception {
  final String mensagem;
  const ErroSemestre(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Acesso aos semestres dos cursos.
///
/// Mesmo modelo dos outros serviços: classe abstrata, para as telas poderem
/// ser testadas sem Firebase trocando [instancia].
///
/// CRUD: [adicionar] (create), [listar] (read), [renumerar] (update) e
/// [excluir] (delete).
abstract class SemestreService {
  static SemestreService instancia = FirebaseSemestreService();

  /// Limite de semestres por curso. Cobre cursos longos (medicina tem 12).
  static const int maximoPorCurso = 12;

  /// Semestres de um curso, em ordem de número, sempre atualizados.
  Stream<List<Semestre>> listar(String cursoId);

  /// Cria o próximo semestre do curso (o maior número existente + 1; ou o 1º,
  /// se o curso ainda não tem nenhum). Lança [ErroSemestre] se o curso já
  /// estiver no [maximoPorCurso] ou se der erro.
  Future<Semestre> adicionar(String cursoId);

  /// Muda o número do semestre. Lança [ErroSemestre] se o número for inválido
  /// ou se o curso já tiver um semestre com esse número.
  Future<void> renumerar(Semestre semestre, int numero);

  /// Exclui o semestre e as disciplinas dele. Lança [ErroSemestre].
  Future<void> excluir(Semestre semestre);
}

class FirebaseSemestreService implements SemestreService {
  // Só toca no Firebase quando é usado, para criar o objeto não exigir
  // Firebase.initializeApp().
  CollectionReference<Map<String, dynamic>> get _colecao =>
      FirebaseFirestore.instance.collection('semestres');

  Query<Map<String, dynamic>> _doCurso(String cursoId) =>
      _colecao.where('cursoId', isEqualTo: cursoId);

  @override
  Stream<List<Semestre>> listar(String cursoId) {
    return _doCurso(cursoId).snapshots().map((resultado) {
      final lista = resultado.docs
          .map((doc) => Semestre.fromMap(doc.id, doc.data()))
          .toList();
      lista.sort((a, b) => a.numero.compareTo(b.numero));
      return lista;
    });
  }

  @override
  Future<Semestre> adicionar(String cursoId) async {
    try {
      final existentes = await _doCurso(cursoId).get();

      var maior = 0;
      for (final doc in existentes.docs) {
        final numero = Semestre.fromMap(doc.id, doc.data()).numero;
        if (numero > maior) maior = numero;
      }

      final proximo = maior + 1;
      if (proximo > SemestreService.maximoPorCurso) {
        throw const ErroSemestre(
          'Um curso pode ter no máximo '
          '${SemestreService.maximoPorCurso} semestres.',
        );
      }

      final referencia = await _colecao.add({
        ...Semestre(id: '', cursoId: cursoId, numero: proximo).toMap(),
        'criadoEm': FieldValue.serverTimestamp(),
      });

      return Semestre(id: referencia.id, cursoId: cursoId, numero: proximo);
    } on FirebaseException catch (e) {
      throw ErroSemestre(_traduzir(e.code));
    }
  }

  @override
  Future<void> renumerar(Semestre semestre, int numero) async {
    if (numero < 1 || numero > SemestreService.maximoPorCurso) {
      throw const ErroSemestre(
        'Informe um número de 1 a ${SemestreService.maximoPorCurso}.',
      );
    }

    try {
      final doCurso = await _doCurso(semestre.cursoId).get();
      final conflito = doCurso.docs.any(
        (doc) =>
            doc.id != semestre.id &&
            Semestre.fromMap(doc.id, doc.data()).numero == numero,
      );
      if (conflito) {
        throw ErroSemestre('Este curso já tem o $numeroº semestre.');
      }

      await _colecao.doc(semestre.id).update({
        'numero': numero,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ErroSemestre(_traduzir(e.code));
    }
  }

  @override
  Future<void> excluir(Semestre semestre) async {
    try {
      // As disciplinas do semestre vão junto, com a grade e as matrículas
      // delas; senão ficariam órfãs no banco.
      final disciplinas = await FirebaseFirestore.instance
          .collection('disciplinas')
          .where('semestreId', isEqualTo: semestre.id)
          .get();
      final lote = FirebaseFirestore.instance.batch();
      for (final doc in disciplinas.docs) {
        await FirebaseDisciplinaService.excluirDependentes(lote, doc.id);
        lote.delete(doc.reference);
      }
      lote.delete(_colecao.doc(semestre.id));
      await lote.commit();
    } on FirebaseException catch (e) {
      throw ErroSemestre(_traduzir(e.code));
    }
  }

  String _traduzir(String codigo) {
    switch (codigo) {
      case 'permission-denied':
        return 'Sem permissão para salvar. Verifique as regras do Firestore.';
      case 'unavailable':
        return 'Sem conexão. Verifique sua internet.';
      case 'not-found':
        return 'Este semestre não existe mais.';
      default:
        return 'Não foi possível salvar o semestre ($codigo).';
    }
  }
}
